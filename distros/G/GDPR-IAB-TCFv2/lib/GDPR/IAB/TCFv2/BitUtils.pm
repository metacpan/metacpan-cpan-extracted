package GDPR::IAB::TCFv2::BitUtils;
use strict;
use warnings;
use integer;
use bytes;
use Math::BigInt;

use Carp qw(croak confess);

require Exporter;
use base qw<Exporter>;

use constant ASCII_OFFSET => ord('A');

my $CAN_PACK_QUADS;
my $CAN_FORCE_BIG_ENDIAN;

BEGIN {
    $CAN_PACK_QUADS       = !!eval { my $f = pack 'Q>'; 1 };
    $CAN_FORCE_BIG_ENDIAN = !!eval { my $f = pack 'S>'; 1 };
}

our @EXPORT_OK = qw<is_set
  get_uint2
  get_uint3
  get_uint6
  get_uint12
  get_uint16
  get_uint36
  get_char6_pair
>;

sub is_set {
    my ( $data, $offset ) = @_;

    my $data_size = length($data);

    croak
      "index out of bounds on offset $offset: can't read 1, only has: $data_size"
      if $offset + 1 > $data_size;

    my $r = substr( $data, $offset, 1 ) == 1;

    return wantarray ? ( $r, $offset + 1 ) : $r;
}

sub get_uint2 {
    my ( $data, $offset ) = @_;

    return _get_big_endian_octet_8bits( $data, $offset, 2 );
}

sub get_uint3 {
    my ( $data, $offset ) = @_;

    return _get_big_endian_octet_8bits( $data, $offset, 3 );
}

sub get_uint6 {
    my ( $data, $offset ) = @_;

    return _get_big_endian_octet_8bits( $data, $offset, 6 );
}

sub get_char6_pair {
    my ( $data, $offset ) = @_;

    my $pair;

    for ( 1 .. 2 ) {
        my ( $byte, $next_offset ) = get_uint6( $data, $offset );

        $pair .= chr( ASCII_OFFSET + $byte );

        $offset = $next_offset;
    }

    return wantarray ? ( $pair, $offset ) : $pair;
}

sub get_uint12 {
    my ( $data, $offset ) = @_;

    return _get_big_endian_short_16bits( $data, $offset, 12 );
}

sub get_uint16 {
    my ( $data, $offset ) = @_;

    return _get_big_endian_short_16bits( $data, $offset, 16 );
}

sub _get_big_endian_octet_8bits {
    my ( $data, $offset, $nbits ) = @_;

    my ( $bits_with_pading, $next_offset ) =
      _get_bits_with_padding( $data, 8, $offset, $nbits );

    my $r = unpack(
        "C",
        $bits_with_pading
    );

    return wantarray ? ( $r, $next_offset ) : $r;
}

sub _get_big_endian_short_16bits {
    my ( $data, $offset, $nbits ) = @_;

    if ($CAN_FORCE_BIG_ENDIAN) {
        my ( $bits_with_pading, $next_offset ) =
          _get_bits_with_padding( $data, 16, $offset, $nbits );

        my $r = unpack( "S>", $bits_with_pading );

        return wantarray ? ( $r, $next_offset ) : $r;
    }

    my ( $data_with_padding, $next_offset ) =
      _add_padding( $data, 16, $offset, $nbits );

    my $r = Math::BigInt->new( "0b" . $data_with_padding );

    return wantarray ? ( $r, $next_offset ) : $r;
}

sub get_uint36 {
    my ( $data, $offset ) = @_;

    if ($CAN_PACK_QUADS) {
        my ( $bits_with_pading, $next_offset ) =
          _get_bits_with_padding( $data, 64, $offset, 36 );

        my $r = unpack( "Q>", $bits_with_pading );

        return wantarray ? ( $r, $next_offset ) : $r;
    }

    my ( $data_with_padding, $next_offset ) =
      _add_padding( $data, 64, $offset, 36 );

    my $r = Math::BigInt->new( "0b" . $data_with_padding );

    return wantarray ? ( $r, $next_offset ) : $r;
}

sub _get_bits_with_padding {
    my ( $data, $bits, $offset, $nbits ) = @_;

    my ( $data_with_padding, $next_offset ) =
      _add_padding( $data, $bits, $offset, $nbits );

    my $r = pack( "B${bits}", $data_with_padding );

    return wantarray ? ( $r, $next_offset ) : $r;
}

sub _add_padding {
    my ( $data, $bits, $offset, $nbits ) = @_;

    my $data_size = length($data);

    croak
      "index out of bounds on offset $offset: can't read $nbits, only has: $data_size"
      if $offset + $nbits > $data_size;

    my $padding = "0" x ( $bits - $nbits );

    my $r = $padding . substr( $data, $offset, $nbits );

    return wantarray ? ( $r, $offset + $nbits ) : $r;
}

1;
__END__

=head1 NAME 

GDPR::IAB::TCFv2::BitUtils - utilities functions to manage bits
 
=head1 SYNOPSIS
    use GDPR::IAB::TCFv2::BitUtils qw<get_uint16>;

    my $data = unpack "B*", decode_base64url('tcf v2 consent string base64 encoded');
    
    my $max_vendor_id_consent = get_uint16($data, 213);

=head1 FUNCTIONS

=head2 is_set

Receive two parameters: data and bit offset.

Will return true if the bit present on bit offset is 1.

    my $is_service_specific = is_set( $data, 138 );

=head2 get_uint2

Receive two parameters: data and bit offset.

Will fetch 2 bits from data since bit offset and convert it an unsigned int.

    my $value = get_uint2( $data, $offset );

=head2 get_uint6

Receive two parameters: data and bit offset.

Will fetch 6 bits from data since bit offset and convert it an unsigned int.

    my $version = get_uint6( $data, 0 );

=head2 get_char6

Similar to L<GDPR::IAB::TCFv2::BitUtils::get_uint6> but perform increment the value with the ascii value of "A" letter and convert to a character.

=head2 get_char6_pair

Receives the data, bit offset and sequence size n.

Returns a string of size n by concatenate L<GDPR::IAB::TCFv2::BitUtils::get_char6> calls.

    my $consent_language = get_char6_pair($data, 108, 2) # returns two letter country encoded as ISO_639-1 

=head2 get_uint12

Receives the data and bit offset.

Will fetch 12 bits from data since bit offset and convert it an unsigned int (short).

    my $cmp_id = get_uint12( $data, 78 );

=head2 get_uint16

Receives the data and bit offset.

Will fetch 16 bits from data since bit offset and convert it an unsigned int (short).

    my $max_vendor_id_consent = get_uint16( $data, 213 );

=head2 get_uint36

Receives the data and bit offset.

Will fetch 36 bits from data since bit offset and convert it an unsigned int (long).

    my $deciseconds = get_uint36( $data, 6 );
    my $created = $deciseconds/2;

