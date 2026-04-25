package Horus;

use 5.008003;
use strict;
use warnings;

our $VERSION = '0.08';

use Exporter 'import';
our @EXPORT_OK = qw(
    uuid_v1 uuid_v2 uuid_v3 uuid_v4 uuid_v5
    uuid_v6 uuid_v7 uuid_v8 uuid_nil uuid_max
    uuid_v4_bulk

    uuid_parse uuid_validate uuid_version uuid_variant
    uuid_cmp uuid_convert uuid_time uuid_is_nil uuid_is_max

    UUID_FMT_STR UUID_FMT_HEX UUID_FMT_BRACES UUID_FMT_URN
    UUID_FMT_BASE64 UUID_FMT_BASE32 UUID_FMT_CROCKFORD
    UUID_FMT_BINARY UUID_FMT_UPPER_STR UUID_FMT_UPPER_HEX

    UUID_NS_DNS UUID_NS_URL UUID_NS_OID UUID_NS_X500
);

our %EXPORT_TAGS = (
    all       => \@EXPORT_OK,
    generate  => [qw(uuid_v1 uuid_v2 uuid_v3 uuid_v4 uuid_v5
                     uuid_v6 uuid_v7 uuid_v8 uuid_nil uuid_max uuid_v4_bulk)],
    util      => [qw(uuid_parse uuid_validate uuid_version uuid_variant
                     uuid_cmp uuid_convert uuid_time uuid_is_nil uuid_is_max)],
    format    => [qw(UUID_FMT_STR UUID_FMT_HEX UUID_FMT_BRACES UUID_FMT_URN
                     UUID_FMT_BASE64 UUID_FMT_BASE32 UUID_FMT_CROCKFORD
                     UUID_FMT_BINARY UUID_FMT_UPPER_STR UUID_FMT_UPPER_HEX)],
    namespace => [qw(UUID_NS_DNS UUID_NS_URL UUID_NS_OID UUID_NS_X500)],
);

require XSLoader;
XSLoader::load('Horus', $VERSION);

sub include_dir {
    my $dir = $INC{'Horus.pm'};
    $dir =~ s{Horus\.pm$}{Horus/include};
    return $dir;
}

1;

__END__

=head1 NAME

Horus - XS UUID/GUID generator supporting all RFC 9562 versions

=head1 SYNOPSIS

    use Horus qw(:all);

    # Generate UUIDs (default: lowercase hyphenated string)
    my $v4  = uuid_v4();
    my $v7  = uuid_v7();
    my $v1  = uuid_v1();

    # Namespace-based (deterministic)
    my $v3 = uuid_v3(UUID_NS_DNS, 'example.com');
    my $v5 = uuid_v5(UUID_NS_DNS, 'example.com');

    # Different output formats
    my $hex    = uuid_v4(UUID_FMT_HEX);        # no hyphens
    my $braces = uuid_v4(UUID_FMT_BRACES);     # {..}
    my $urn    = uuid_v4(UUID_FMT_URN);         # urn:uuid:..
    my $b64    = uuid_v4(UUID_FMT_BASE64);      # 22-char base64
    my $b32    = uuid_v4(UUID_FMT_BASE32);      # 26-char base32
    my $crk    = uuid_v4(UUID_FMT_CROCKFORD);   # 26-char Crockford
    my $bin    = uuid_v4(UUID_FMT_BINARY);       # raw 16 bytes

    # Batch generation (single Perl/C crossing)
    my @uuids = uuid_v4_bulk(1000);

    # Special UUIDs
    my $nil = uuid_nil();
    my $max = uuid_max();

    # Utilities
    my $valid   = uuid_validate($string);
    my $ver     = uuid_version($string);
    my $cmp     = uuid_cmp($uuid_a, $uuid_b);
    my $epoch   = uuid_time($v7);
    my $binary  = uuid_parse($string);
    my $other   = uuid_convert($string, UUID_FMT_BASE64);

    # OO interface
    my $gen = Horus->new(format => UUID_FMT_STR, version => 4);
    my $uuid  = $gen->generate;
    my @batch = $gen->bulk(1000);

=head1 DESCRIPTION

Horus is a pure XS UUID generator with no external C library dependencies.
It supports all UUID versions defined in RFC 9562 (v1-v8) plus NIL and MAX,
with 10 output format options.

Performance target: 5M+ v4 UUIDs/sec via random pool buffering, pre-computed
hex lookup tables, and minimal Perl/C boundary crossings.

=head1 UUID VERSIONS

=over 4

=item B<v1> - Time-based (Gregorian timestamp + clock sequence + node)

=item B<v2> - DCE Security (like v1, with local domain identifiers)

=item B<v3> - MD5 namespace (deterministic: MD5 of namespace + name)

=item B<v4> - Random (122 random bits)

=item B<v5> - SHA-1 namespace (deterministic: SHA-1 of namespace + name)

=item B<v6> - Reordered time (v1 reorganised for lexical sorting)

=item B<v7> - Unix epoch time (48-bit ms timestamp + random, monotonic)

=item B<v8> - Custom (application-defined data with version/variant stamped)

=item B<NIL> - All zeros (00000000-0000-0000-0000-000000000000)

=item B<MAX> - All ones (ffffffff-ffff-ffff-ffff-ffffffffffff)

=back

=head1 OUTPUT FORMATS

=over 4

=item C<UUID_FMT_STR> - Lowercase hyphenated (default): C<550e8400-e29b-41d4-a716-446655440000>

=item C<UUID_FMT_HEX> - Lowercase no hyphens: C<550e8400e29b41d4a716446655440000>

=item C<UUID_FMT_BRACES> - Braces: C<{550e8400-e29b-41d4-a716-446655440000}>

=item C<UUID_FMT_URN> - URN: C<urn:uuid:550e8400-e29b-41d4-a716-446655440000>

=item C<UUID_FMT_BASE64> - Base64 (22 chars, no padding)

=item C<UUID_FMT_BASE32> - Base32 RFC 4648 (26 chars)

=item C<UUID_FMT_CROCKFORD> - Crockford Base32 (26 chars, sortable)

=item C<UUID_FMT_BINARY> - Raw 16 bytes

=item C<UUID_FMT_UPPER_STR> - Uppercase hyphenated

=item C<UUID_FMT_UPPER_HEX> - Uppercase no hyphens

=back

=head1 NAMESPACE CONSTANTS

=over 4

=item C<UUID_NS_DNS> - C<6ba7b810-9dad-11d1-80b4-00c04fd430c8>

=item C<UUID_NS_URL> - C<6ba7b811-9dad-11d1-80b4-00c04fd430c8>

=item C<UUID_NS_OID> - C<6ba7b812-9dad-11d1-80b4-00c04fd430c8>

=item C<UUID_NS_X500> - C<6ba7b814-9dad-11d1-80b4-00c04fd430c8>

=back

=head1 AUTHOR

LNATION E<lt>email@lnation.orgE<gt>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
