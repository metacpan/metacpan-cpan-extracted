package File::Raw::Hash;

use 5.008003;
use strict;
use warnings;

our $VERSION = '0.03';

use base 'File::Raw';

require XSLoader;
XSLoader::load('File::Raw::Hash', $VERSION);

1;

__END__

=head1 NAME

File::Raw::Hash - Cryptographic and integrity digests as a File::Raw plugin

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

Loading the module registers one plugin (C<hash>) with File::Raw. It
is a B<passthrough> on the data path: bytes flow through unchanged,
and the digest is delivered through a caller-supplied scalar or hash
reference passed via the C<into> option.

    use File::Raw::Hash;
    use File::Raw qw(import);

    # Single algorithm, scalar destination.
    my $bytes = file_slurp("input.bin",
        plugin => 'hash',
        algo   => 'sha256',
        into   => \my $digest,
    );
    # $digest is now the lowercase-hex SHA-256 of the file.

    # Multiple algorithms in one pass; result lands in a hash.
    my %digests;
    file_slurp("input.bin",
        plugin => 'hash',
        algos  => [qw(sha256 md5 crc32)],
        into   => \%digests,
    );

    # Streaming: each_line digests the file in chunks; the digest
    # arrives in $d after iteration completes. RAM stays bounded
    # regardless of file size.
    each_line("huge.log", sub { ... },
        plugin => 'hash',
        algo   => 'sha256',
        into   => \my $d,
    );

    # Same plugin, write side. The bytes spewed are the original
    # payload; the digest of that payload lands in $d.
    file_spew("output.bin", $payload,
        plugin => 'hash',
        algo   => 'sha256',
        into   => \my $d,
    );

=head1 OPTIONS

=over 4

=item C<algo>

Single algorithm name. One of C<sha256> (default), C<sha512>, C<sha1>,
C<md5>, C<crc32>, C<xxh64>, C<blake3>. Names are case-insensitive and
tolerate dashes / underscores: C<SHA-256>, C<sha_256>, C<SHA256> all
resolve to the same algorithm. Mutually exclusive with C<algos>.

=item C<algos>

Arrayref of algorithm names; one pass, all digests computed in
lockstep. The result hash is keyed by canonical lowercase name
(C<sha256>, not C<SHA-256>). Mutually exclusive with C<algo>.

=item C<into>

B<Required.> Where the digest goes.

=over 4

=item *

For single-algo mode (C<algo> or default): a B<scalar reference>. The
referent is overwritten with the formatted digest.

=item *

For multi-algo mode (C<algos>): a B<hash reference>. Existing keys are
left alone; one entry is stored per requested algo.

=back

=item C<format>

Output format. One of:

=over 4

=item C<hex> (default) - lowercase hexadecimal.

=item C<HEX> - uppercase hexadecimal. Note this name is case-sensitive: that's the signal.

=item C<base64> - RFC 4648 section 4 base64, padded with C<=>.

=item C<base64url> - RFC 4648 section 5 URL-safe base64, no padding.

=item C<raw> - Raw binary digest bytes.

=back

=item C<hmac_key>

If set, switches the algorithm to RFC 2104 HMAC mode. Available for
C<sha256>, C<sha512>, C<sha1>, and C<md5>; rejected for C<crc32>,
C<xxh64>, and C<blake3>. The key may be any byte string, including
binary or empty; keys longer than the algorithm's block size are
hashed down per the spec.

    my $mac;
    file_slurp("payload.bin",
        plugin   => 'hash',
        algo     => 'sha256',
        hmac_key => $secret,
        into     => \$mac,
    );

=item C<xxh64_seed>

Seed for the C<xxh64> algorithm. Default C<0>. Ignored by every other
algorithm.

=back

=head1 PHASES

C<read>, C<write>, C<stream>, and C<record> are all implemented.

The plugin is a B<passthrough> on read and write - the byte stream is
returned unchanged. C<record_fn> behaves the same way: the original
record is returned and a digest is appended to the caller-supplied
arrayref. RECORD-phase output goes into an arrayref (one entry per
record), regardless of single/multi algo:

    my @per_line_digests;
    # File::Raw 0.11+ does not yet expose a public per-record iterator
    # API; the helper below dispatches a single record at a time and
    # is the same path future high-level entry points will use.
    File::Raw::Hash::_test_record_one("the line",
        algo => 'sha256',
        into => \@per_line_digests);

The plugin is a B<passthrough> on read and write - the byte stream is
returned unchanged. That makes it composable in a chain anywhere the
caller wants to checksum a particular representation:

    # Hash the wire bytes (the .gz file as it sits on disk):
    my $payload = file_slurp("data.json.gz",
        plugin => ['hash', 'gzip', 'json'],
        hash   => { algo => 'sha256', into => \my $disk_digest },
    );

    # Hash the decompressed payload (after gunzip, before JSON parse):
    my $payload = file_slurp("data.json.gz",
        plugin => ['gzip', 'hash', 'json'],
        hash   => { algo => 'sha256', into => \my $payload_digest },
    );

(Plugin chains require File::Raw 0.10+.)

=head1 ALGORITHM CHOICE

=over 4

=item *

B<sha256> - modern default. Cryptographically secure for new designs.

=item *

B<sha512> - same security family, faster on 64-bit hosts for large
inputs because it processes 1024-bit blocks.

=item *

B<sha1> - kept for git/openssh/legacy interop. Cryptographically
broken; do not use for new security designs.

=item *

B<md5> - kept for content fingerprinting and upstream interop (etags,
checksum manifests). Cryptographically broken; do not use for security.

=item *

B<crc32> - IEEE 802.3 polynomial, the same CRC zlib/gzip/PNG/Ethernet
use. Not a hash function; use only for integrity / dedup, never for
authenticity.

=item *

B<xxh64> - non-cryptographic 64-bit hash by Yann Collet. Very fast;
useful for content fingerprinting / dedup. Optional 64-bit seed via
the C<xxh64_seed> option (default 0). Not for security.

=item *

B<blake3> - modern cryptographic hash (32-byte default output). Faster
than SHA-2 family on most modern hardware. Sequential reference
implementation (no SIMD) in v0.01; multi-threaded fan-out is a future
enhancement.

=back

=head1 IMPLEMENTATION

All algorithms are vendored, public-domain reference implementations.
There is B<no> external library dependency (no OpenSSL, no libsodium).

=head1 SEE ALSO

L<File::Raw>, L<Digest::SHA>, L<Digest::MD5>, L<Digest::CRC>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
