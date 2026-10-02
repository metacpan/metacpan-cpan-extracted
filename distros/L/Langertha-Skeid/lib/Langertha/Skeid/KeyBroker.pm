package Langertha::Skeid::KeyBroker;
our $VERSION = '0.003';
# ABSTRACT: Pluggable API key resolution for Skeid nodes
use Moo;
use Carp qw(croak);
use namespace::clean;



has cache_ttl => (
  is      => 'rw',
  default => sub { 300 },
);


has negative_cache_ttl => (
  is      => 'rw',
  default => sub { 5 },
);

# ref => { key => $key_or_undef, error => $msg_or_undef, expires => $epoch }
has _cache => (
  is      => 'ro',
  default => sub { {} },
);

# ref => [ @callbacks ] for a resolution currently in flight
has _pending => (
  is      => 'ro',
  default => sub { {} },
);


sub resolve_key {
  my ($self, $ref) = @_;
  croak ref($self) . " must implement resolve_key()";
}


sub key_async {
  my ($self, $ref, $cb) = @_;
  $cb ||= sub { };
  return $cb->(undef, 'no key reference') unless defined($ref) && length($ref);

  if (my $hit = $self->cached_key($ref)) {
    $cb->($hit->{key}, $hit->{error});
    return;
  }

  # One round-trip per reference, however many requests are waiting on it. Without this, a cold
  # cache at concurrency 64 is 64 identical vault calls -- and the moment a key expires, every
  # in-flight request misses at once.
  my $pending = $self->_pending;
  if ($pending->{$ref}) {
    push @{$pending->{$ref}}, $cb;
    return;
  }
  $pending->{$ref} = [$cb];

  $self->resolve_key_async($ref, sub {
    my ($key, $error) = @_;
    $key = undef unless defined($key) && length($key);
    $self->_cache_result($ref, $key, $error);
    my $waiting = delete($pending->{$ref}) || [];
    $_->($key, $error) for @$waiting;
  });
  return;
}


sub resolve_key_async {
  my ($self, $ref, $cb) = @_;
  my $key = eval { $self->resolve_key($ref) };
  my $error = $@ ? do { my $e = "$@"; $e =~ s/\s+\z//; $e } : undef;
  $key = undef unless defined($key) && length($key);
  $error //= 'no key resolved' unless defined $key;
  $cb->($key, $error);
  return;
}


sub cached_key {
  my ($self, $ref) = @_;
  return unless defined($ref) && length($ref);
  my $hit = $self->_cache->{$ref} or return;
  if ($hit->{expires} <= time) {
    delete $self->_cache->{$ref};
    return;
  }
  return $hit;
}


sub forget_key {
  my ($self, $ref) = @_;
  if (defined($ref) && length($ref)) {
    delete $self->_cache->{$ref};
    return 1;
  }
  %{$self->_cache} = ();
  return 1;
}

sub _cache_result {
  my ($self, $ref, $key, $error) = @_;
  my $ttl = defined($key) ? $self->cache_ttl : $self->negative_cache_ttl;
  return unless $ttl > 0;
  $self->_cache->{$ref} = { key => $key, error => $error, expires => time + $ttl };
  return;
}


sub needs_refresh { 0 }


sub refresh { }


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Skeid::KeyBroker - Pluggable API key resolution for Skeid nodes

=head1 VERSION

version 0.003

=head1 DESCRIPTION

The contract that turns a key reference (C<secret/skeid/remote/groq>) into a secret, in memory,
at the moment it is needed. L<Langertha::Skeid::KeyBroker::OpenBao> is the implementation;
this class is what code depends on.

Implement L</resolve_key> in a subclass. Everything else — caching, request coalescing, the
non-blocking entry point — is provided here, so a three-line broker gets them for free.

=head2 Two entry points, and which one is yours

L</key_async> is the B<only> one the request path may call. It answers from cache without
touching the loop, and a miss is one round-trip however many requests are waiting on it.

L</resolve_key> is what a subclass implements and what off-loop code (CLI, tests, setup
scripts) may call directly. Calling it from a Mojolicious handler blocks every other in-flight
request for the duration of the vault round-trip — see ADR 0005.

=head2 cache_ttl

How long a resolved key stays in memory, in seconds (default 300, 0 disables caching).
Memory only: ADR 0003 forbids a disk cache, not this one. The cost of a stale key is one
failed upstream call after a rotation; the cost of no cache is a vault round-trip on the
request path, per request.

=head2 negative_cache_ttl

How long a failed resolution is remembered, in seconds (default 5, 0 disables). Short on
purpose: it exists so a vault outage costs one round-trip per reference per few seconds
instead of one per request, not to make a fixed misconfiguration stick.

=head2 resolve_key

  my $key = $broker->resolve_key('secret/skeid/remote/groq');

What a subclass implements: resolve one reference, return the secret, die or return undef when
it cannot. Blocking. Never call it from a request handler — call L</key_async>.

=head2 key_async

  $broker->key_async($ref, sub {
    my ($key, $error) = @_;
    ...
  });

The request path's entry point. The callback always runs exactly once, with the key, or with
undef and a message. A cached answer calls back immediately and synchronously.

=head2 resolve_key_async

  $broker->resolve_key_async($ref, sub { my ($key, $error) = @_; ... });

The non-blocking half of L</resolve_key>, for subclasses that can do better than blocking. The
default implementation calls C<resolve_key> and hands the result to the callback, which keeps
a simple broker correct — but keeps it blocking. L<Langertha::Skeid::KeyBroker::OpenBao>
overrides it.

Callers want L</key_async>: this one is uncached and uncoalesced.

=head2 cached_key

  my $hit = $broker->cached_key($ref);   # { key => …, error => … } or nothing

The live cache entry for a reference, or nothing when there is none or it has expired.
Distinguishes "cached failure" from "not cached" — both would look like undef otherwise.

=head2 forget_key

  $broker->forget_key($ref);   # one reference
  $broker->forget_key;         # all of them

Drops cached resolutions, so the next request resolves again. What a key rotation calls.

=head2 needs_refresh

True when the broker's own credential has to be renewed before the next resolution. Always 0
here; L<Langertha::Skeid::KeyBroker::OpenBao> overrides it.

=head2 refresh

Renews the broker's own credential. A no-op here; L<Langertha::Skeid::KeyBroker::OpenBao>
overrides it.

=head1 SEE ALSO

L<Langertha::Skeid::KeyBroker::OpenBao>, L<Langertha::Skeid/key_broker>, and ADR 0003 (secrets
live in memory only) in the distribution repository.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha-skeid/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
