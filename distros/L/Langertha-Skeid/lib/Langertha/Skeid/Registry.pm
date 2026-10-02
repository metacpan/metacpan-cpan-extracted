package Langertha::Skeid::Registry;
our $VERSION = '0.003';
# ABSTRACT: Signed Skeid-to-Skeid capacity snapshots: encoding, signing, verification, mapping
use strict;
use warnings;
use Digest::SHA qw(hmac_sha256_hex);
use JSON::MaybeXS ();
use Langertha::Skeid::Secret;
use Time::HiRes ();



sub SIGNATURE_HEADER { 'X-Skeid-Registry-Signature' }


sub SCHEMA_VERSION { 1 }


sub MIN_SECRET_BYTES { 32 }

my $JSON = JSON::MaybeXS->new(canonical => 1, utf8 => 1);


sub encode {
  my ($class, $snapshot) = @_;
  return $JSON->encode($snapshot);
}


sub sign {
  my ($class, $body, $secret) = @_;
  return 'sha256=' . hmac_sha256_hex($body, $secret);
}


sub signed_snapshot {
  my ($class, $skeid) = @_;
  my $secret = $skeid->registry_secret // '';
  die "registry secret is not set; a snapshot is never published unsigned\n" unless length $secret;
  my $body = $class->encode($skeid->registry_snapshot);
  return ($body, $class->sign($body, $secret));
}


sub verify {
  my ($class, $body, $header, $secret) = @_;
  return 0 unless defined($body) && defined($header) && defined($secret) && length($secret);
  my $want = $class->sign($body, $secret);
  $header =~ s/\A\s+|\s+\z//g;
  return Langertha::Skeid::Secret->equal($header, $want);
}


sub reading_from_snapshot {
  my ($class, $snapshot, %args) = @_;
  my @want = map { lc } grep { defined && length } @{ $args{tags} || [] };
  my $now = Time::HiRes::time();

  my ($limit, $free, $selected) = (0, 0, 0);
  for my $node (@{ $snapshot->{nodes} || [] }) {
    next unless ref($node) eq 'HASH';
    next unless $node->{healthy};
    if (@want) {
      my %have = map { lc($_) => 1 } grep { defined } @{ ref($node->{tags}) eq 'ARRAY' ? $node->{tags} : [] };
      next if grep { !$have{$_} } @want;
    }
    $selected++;

    my $max      = _num($node->{max_conns});
    my $inflight = _num($node->{inflight});
    my $cap      = ref($node->{capacity}) eq 'HASH' ? $node->{capacity} : undef;
    my $cap_limit = $cap ? _num($cap->{limit}) : 0;
    my $backoff  = ($cap && $cap->{retry_after} && _num($cap->{retry_after}) > $now) ? 1 : 0;

    my $node_limit = $max > 0 ? $max : $cap_limit;
    if ($node_limit <= 0) {
      # Nothing bounds this node, so nothing bounds the downstream -- unless it is backing off,
      # in which case it simply has no slots to offer.
      next if $backoff;
      return { used => undef, limit => undef };
    }

    my $node_free = $max > 0 ? $max - $inflight : $node_limit;
    if ($cap_limit > 0) {
      my $cap_free = $cap_limit - _num($cap->{used});
      $node_free = $cap_free if $cap_free < $node_free;
    }
    $node_free = 0 if $backoff;
    $node_free = 0 if $node_free < 0;
    $node_free = $node_limit if $node_free > $node_limit;

    $limit += $node_limit;
    $free  += $node_free;
  }

  return { used => 1, limit => 1 } if !$selected || $limit <= 0;
  return { used => $limit - $free, limit => $limit };
}

sub _num {
  my ($value) = @_;
  return 0 unless defined $value && !ref $value && $value =~ /\A-?\d+(?:\.\d+)?(?:[eE][-+]?\d+)?\z/;
  return 0 + $value;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Skeid::Registry - Signed Skeid-to-Skeid capacity snapshots: encoding, signing, verification, mapping

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  # downstream: what GET /skeid/registry/snapshot sends
  my ($body, $signature) = Langertha::Skeid::Registry->signed_snapshot($skeid);

  # fronting tier: what CapacityProbe::Registry does with it
  Langertha::Skeid::Registry->verify($body, $signature, $secret) or die 'bad signature';
  my $reading = Langertha::Skeid::Registry->reading_from_snapshot($snapshot, tags => ['local']);

=head1 DESCRIPTION

The two halves of the registry (ADR 0017) share one module, so the bytes one side signs are
the bytes the other side checks and the mapping to a capacity reading is written down once.

The signature is C<sha256=> plus the hex HMAC-SHA256 of the exact response body, in the
L</SIGNATURE_HEADER>. C<generated_at> and C<ttl> sit inside the signed body, so a snapshot's age
cannot be changed without breaking it.

=head2 SIGNATURE_HEADER

C<X-Skeid-Registry-Signature>.

=head2 SCHEMA_VERSION

The snapshot schema this code writes and accepts: 1.

=head2 MIN_SECRET_BYTES

The shortest signing secret either side accepts: 32 bytes, the HMAC-SHA256 output size. A
downstream with a shorter one fails its config load; a fronting probe with one reports
C<missing_secret>.

=head2 encode

  my $body = Langertha::Skeid::Registry->encode($snapshot);

Canonical JSON bytes (sorted keys).

=head2 sign

  my $signature = Langertha::Skeid::Registry->sign($body, $secret);   # 'sha256=...'

C<sha256=> plus the hex HMAC-SHA256 of C<$body> under C<$secret>.

=head2 signed_snapshot

  my ($body, $signature) = Langertha::Skeid::Registry->signed_snapshot($skeid);

L<Langertha::Skeid/registry_snapshot>, encoded and signed with the Skeid's C<registry_secret>.
Dies without a secret: a snapshot is never published unsigned.

=head2 verify

  my $ok = Langertha::Skeid::Registry->verify($body, $signature_header, $secret);

True when the header is the signature of these exact bytes under this secret. The comparison
takes the same time wherever the first difference is, so a caller cannot find the signature
one character at a time.

=head2 reading_from_snapshot

  my $reading = Langertha::Skeid::Registry->reading_from_snapshot($snapshot, tags => \@tags);
  # { used => 5, limit => 16 }  or  { used => undef, limit => undef }  (no ceiling)

Turns a verified snapshot into the one capacity reading admission consumes for the node that
stands for this downstream. Over the downstream nodes that are healthy and carry every tag in
C<tags>:

=over 4

=item * C<free> per node is C<max_conns - inflight>, at most C<limit - used> of the node's own
capacity reading when it has one with a limit, and 0 while its backoff is pending. Never below
0, never above the node's limit.

=item * C<limit> is the sum of the nodes' limits (C<max_conns>, or the reading's limit for a
node without one), C<used> is C<limit> minus the summed C<free>.

=item * A node with no ceiling at all (C<max_conns> 0 and no limited reading) makes the whole
downstream unbounded: the reading has no limit and does not narrow admission.

=item * No selected healthy node: reported as full (C<used> 1 of C<limit> 1). That downstream
would answer C<503>, so routing should go elsewhere.

=back

C<used> is the downstream's own number. It is never added to what this process counts in
C<inflight>: the requests this process sent are already in it (ADR 0017).

=head1 SEE ALSO

L<Langertha::Skeid/registry_snapshot> and L<Langertha::Skeid/registry_enabled> (publishing),
L<Langertha::Skeid::CapacityProbe::Registry> (reading), L<Langertha::Skeid::Secret>

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
