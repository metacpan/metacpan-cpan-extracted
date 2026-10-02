package Langertha::Skeid::CapacityProbe::Registry;
our $VERSION = '0.003';
# ABSTRACT: Capacity probe reading a downstream Skeid's signed registry snapshot
use Moo;
use Carp qw(croak);
use Mojo::UserAgent;
use JSON::MaybeXS qw(decode_json);
use Scalar::Util qw(looks_like_number);
use Time::HiRes ();
use Langertha::Skeid::Registry;
use namespace::clean;

extends 'Langertha::Skeid::CapacityProbe';


my %KNOWN = map { $_ => 1 } qw(probe type url path read_key_env admin_key_env secret_env interval_ms tags max_skew_s);


sub validate_config {
  my ($class, $cfg, $node_id) = @_;
  my $where = "node '" . ($node_id // '?') . "' capacity (registry)";
  croak "$where must be a hashref" unless ref($cfg) eq 'HASH';
  for my $key (sort keys %$cfg) {
    croak "$where: unknown key '$key' (secrets are named by read_key_env / admin_key_env / "
      . 'secret_env, never '
      . 'written into the config)'
      unless $KNOWN{$key};
  }
  my $named = sub { my $value = $cfg->{$_[0]}; defined($value) && !ref($value) && length($value) };
  croak "$where: secret_env is required" unless $named->('secret_env');
  for my $key (qw(read_key_env admin_key_env)) {
    croak "$where: $key must name an environment variable"
      if defined($cfg->{$key}) && !$named->($key);
  }
  croak "$where: read_key_env (or admin_key_env) is required"
    unless $named->('read_key_env') || $named->('admin_key_env');
  if (defined $cfg->{url}) {
    croak "$where: url must be an absolute http(s) URL"
      if ref($cfg->{url}) || $cfg->{url} !~ m{\Ahttps?://[^/?#]+}i;
  }
  if (defined $cfg->{interval_ms}) {
    croak "$where: interval_ms must be a positive number"
      unless looks_like_number($cfg->{interval_ms}) && $cfg->{interval_ms} > 0;
  }
  if (defined $cfg->{max_skew_s}) {
    croak "$where: max_skew_s must be a number >= 0"
      unless looks_like_number($cfg->{max_skew_s}) && $cfg->{max_skew_s} >= 0;
  }
  if (defined $cfg->{tags}) {
    croak "$where: tags must be a list or a string"
      if ref($cfg->{tags}) && ref($cfg->{tags}) ne 'ARRAY';
  }
  return 1;
}

has _ua => (
  is      => 'lazy',
  builder => sub {
    my $ua = Mojo::UserAgent->new;
    $ua->connect_timeout(2);
    # Shorter than the poll interval, for the reason the Prometheus probe gives: a poll still
    # out when the next tick fires is a probe queueing on itself.
    $ua->request_timeout(3);
    return $ua;
  },
);

has _inflight_poll => (
  is      => 'rw',
  default => sub { 0 },
);


has state => (
  is      => 'rwp',
  default => sub { undef },
);

# generated_at of the last accepted snapshot; nothing older is believed after it.
has _last_generated_at => (
  is      => 'rw',
  default => sub { undef },
);


sub url {
  my ($self) = @_;
  my $cfg = $self->config;
  return $cfg->{url} if defined($cfg->{url}) && length($cfg->{url});

  my ($node) = grep { ($_->{id} // '') eq $self->node_id } @{$self->skeid->nodes};
  my $base = $node ? ($node->{url} // '') : '';
  $base =~ s{/v\d+/?$}{};
  $base =~ s{/+$}{};
  my $path = $cfg->{path} // '/skeid/registry/snapshot';
  $path = "/$path" unless $path =~ m{^/};
  return $base . $path;
}

sub _tags {
  my ($self) = @_;
  my $tags = $self->config->{tags};
  return [] unless defined $tags;
  return [ ref($tags) eq 'ARRAY' ? @$tags : split(/[,\s]+/, "$tags") ];
}


sub source { 'registry' }


sub poll {
  my ($self) = @_;
  return if $self->_inflight_poll;

  my $cfg = $self->config;
  my $secret = defined($cfg->{secret_env})    ? ($ENV{$cfg->{secret_env}}    // '') : '';
  # The read key when configured, never falling back to the admin key: an operator who named
  # a read key does not want the admin key on the wire (skeid #49).
  my $key_env = defined($cfg->{read_key_env}) ? 'read_key_env' : 'admin_key_env';
  my $bearer  = defined($cfg->{$key_env}) ? ($ENV{$cfg->{$key_env}} // '') : '';
  unless (length($secret) && length($bearer)) {
    return $self->_reject(missing_secret => "$key_env or secret_env is not set");
  }
  # The downstream refuses to publish with a shorter secret, so no snapshot could verify.
  if (length($secret) < Langertha::Skeid::Registry->MIN_SECRET_BYTES) {
    return $self->_reject(missing_secret => 'secret_env is shorter than '
      . Langertha::Skeid::Registry->MIN_SECRET_BYTES . ' bytes');
  }

  $self->_inflight_poll(1);
  $self->_ua->get($self->url => { Authorization => "Bearer $bearer" } => sub {
    my (undef, $tx) = @_;
    $self->_inflight_poll(0);
    # Stopped while the request was out: this answer belongs to no running probe.
    return if $self->is_stopped;
    $self->_consume($tx->res, $secret);
  });
  return;
}

sub _consume {
  my ($self, $res, $secret) = @_;
  my $status = $res->code // 0;
  return $self->_reject(unreachable => "HTTP $status")
    unless $status >= 200 && $status < 300;

  my $body = $res->body;
  my $signature = $res->headers->header(Langertha::Skeid::Registry->SIGNATURE_HEADER);
  return $self->_reject(bad_signature => 'signature missing or not valid for this body')
    unless Langertha::Skeid::Registry->verify($body, $signature, $secret);

  my $snapshot = eval { decode_json($body) };
  return $self->_reject(malformed => 'body is not a JSON object') unless ref($snapshot) eq 'HASH';
  return $self->_reject(malformed => 'unknown schema version')
    unless ($snapshot->{version} // '') eq Langertha::Skeid::Registry->SCHEMA_VERSION;
  my ($generated_at, $ttl) = @{$snapshot}{qw(generated_at ttl)};
  return $self->_reject(malformed => 'generated_at / ttl missing')
    unless looks_like_number($generated_at) && looks_like_number($ttl) && $ttl > 0;

  my $now  = Time::HiRes::time();
  my $skew = defined($self->config->{max_skew_s}) ? 0 + $self->config->{max_skew_s} : 5;
  return $self->_reject(future => 'generated_at is ahead of this clock by more than max_skew_s')
    if $generated_at > $now + $skew;
  return $self->_reject(stale => 'older than its ttl')
    if $now - $generated_at > $ttl;
  my $last = $self->_last_generated_at;
  return $self->_reject(replayed => 'older than the last snapshot accepted')
    if defined($last) && $generated_at < $last;

  $self->_last_generated_at(0 + $generated_at);
  my $reading = Langertha::Skeid::Registry->reading_from_snapshot($snapshot, tags => $self->_tags);
  $self->skeid->set_capacity_reading(
    $self->node_id,
    source      => $self->source,
    used        => $reading->{used},
    limit       => $reading->{limit},
    at          => 0 + $generated_at,
    expires_at  => $generated_at + $ttl,
    interval_ms => $self->poll_interval_seconds * 1000,
  );
  $self->_enter('accepted');
  return;
}

# Unknown means inflight decides -- but only this probe's reading is dropped. A backoff another
# source recorded is still true whatever this snapshot was.
sub _reject {
  my ($self, $state, $detail) = @_;
  $self->_forget_own;
  $self->_enter($state, $detail);
  return;
}

sub _enter {
  my ($self, $state, $detail) = @_;
  my $was = $self->state;
  $self->_set_state($state);
  return if defined($was) && $was eq $state;
  # The first success is the expected case and not worth a line; everything else is.
  return if !defined($was) && $state eq 'accepted';
  warn "registry probe for '" . $self->node_id . "': $state"
    . (defined $detail ? " ($detail)" : '') . "\n";
  return;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Skeid::CapacityProbe::Registry - Capacity probe reading a downstream Skeid's signed registry snapshot

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  # fronting tier: one node per downstream Skeid
  nodes:
    - id: skeid-b
      url: http://skeid-b:8090/v1
      model: qwen3-32b
      max_conns: 64
      capacity:
        probe: registry                  # or type: registry
        read_key_env: SKEID_B_READ_KEY   # the downstream's registry read key (preferred)
        # admin_key_env: SKEID_B_ADMIN_KEY   # or its admin API key, when it has no read key
        secret_env: SKEID_REGISTRY_SECRET
        interval_ms: 2000
        # url: http://skeid-b:8090/skeid/registry/snapshot   (default: derived from the node URL)
        # tags: [local]                  # count only downstream nodes carrying these tags
        # max_skew_s: 5                  # how far in the future a snapshot may claim to be

=head1 DESCRIPTION

When the node is another Skeid, the number C<inflight> keeps trying to reconstruct already
exists over there, in memory: per upstream node, what is in flight and what that process may
admit. This probe pulls it from the downstream's C<GET /skeid/registry/snapshot> (published
when the downstream sets C<registry.enabled>) and turns it into the node's capacity reading.
See ADR 0017.

A snapshot is believed only when all of this holds; otherwise the probe forgets its reading
and admission falls back to C<inflight>:

=over 4

=item * the answer is C<200> and its C<X-Skeid-Registry-Signature> verifies against the exact
body with the secret from C<secret_env>;

=item * the schema C<version> is 1;

=item * it is fresh -- not older than its own C<ttl>, not more than C<max_skew_s> in the future;

=item * it is not older than the last snapshot this probe accepted (a replay).

=back

The bearer token is the downstream's registry read key from C<read_key_env> when that is
configured -- it opens the snapshot route and nothing else -- and its admin API key from
C<admin_key_env> only otherwise (skeid #49). With C<read_key_env> set the admin key is never
sent, not even when the read key variable is empty.

A missing C<secret_env> value or bearer key value forgets too, and so does a secret shorter
than 32 bytes (the downstream would refuse to publish with it). The probe forgets only its own
reading, so a C<429> backoff recorded from a response survives a rejected snapshot. The
reading is stamped with the snapshot's C<generated_at> and expires at C<generated_at + ttl>.

How the snapshot becomes C<used> and C<limit> is
L<Langertha::Skeid::Registry/reading_from_snapshot>. It is never added to this process's own
C<inflight>; the node's C<max_conns> stays the guardrail and the reading can only narrow it
(ADR 0009). Where another probe reads the same node, the tighter reading wins while it is
current (L<Langertha::Skeid/set_capacity_reading>).

Every change of state -- accepted, unreachable, bad signature, malformed, stale, from the
future, replayed, missing secret -- is warned once, not on every poll.

=head2 validate_config

  Langertha::Skeid::CapacityProbe::Registry->validate_config($capacity_block, $node_id);

Croaks on a block this probe cannot work with: no C<secret_env>, neither C<read_key_env> nor
C<admin_key_env>, an unknown
key (a secret written into the config instead of named by variable is the one that matters), a
non-http(s) C<url>, a non-positive C<interval_ms>. Called when a node is added, so a bad block
fails the config load or the admin API call instead of forgetting silently on every poll.

=head2 state

The probe's last state: C<accepted>, C<unreachable>, C<bad_signature>, C<malformed>, C<stale>,
C<future>, C<replayed> or C<missing_secret>; undef before the first answer.

=head2 url

The snapshot endpoint: C<url> from the C<capacity> block, else the node's URL with a trailing
C</v1> removed plus C</skeid/registry/snapshot> (C<path> overrides that suffix).

=head2 source

C<registry>.

=head2 poll

Fetches the snapshot from L</url> without blocking, one request at a time, with the bearer
token described above, and checks and maps it as described above. Reports nothing (and forgets
its own reading, setting L</state> to C<missing_secret>) when the secret or bearer variable is
empty or the secret is too short.

=head1 SEE ALSO

L<Langertha::Skeid::Registry>, L<Langertha::Skeid/registry_enabled> (the publishing side),
L<Langertha::Skeid::CapacityProbe>

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
