package GDPR::IAB::TCFv2::BitUtils 0.520;
use v5.12;
use warnings;
use integer;
use bytes;
use Math::BigInt;

use Carp qw(croak confess);

require Exporter;
use parent qw<Exporter>;

use constant ASCII_OFFSET => ord('A');

our $CAN_PACK_QUADS;
our $CAN_FORCE_BIG_ENDIAN;

BEGIN {
  $CAN_PACK_QUADS       = !!eval { pack 'Q>', 1 };
  $CAN_FORCE_BIG_ENDIAN = !!eval { pack 'S>', 1 };
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
  my ($data, $offset) = @_;

  my $byte_offset = $offset >> 3;
  my $bit_in_byte = $offset & 7;

  # TCF is MSB-first. vec(..., 1) addresses bits from LSB to MSB.
  # So bit 0 of the spec is bit 7 of the byte for vec().
  my $vec_offset = ($byte_offset << 3) | (7 - $bit_in_byte);

  croak "index out of bounds on offset $offset: can't read 1" if ($byte_offset >= length($data));

  my $r = vec($data, $vec_offset, 1);

  return wantarray ? ($r, $offset + 1) : $r;
}

sub get_uint2 {
  my ($data, $offset) = @_;
  return _get_bits($data, $offset, 2);
}

sub get_uint3 {
  my ($data, $offset) = @_;
  return _get_bits($data, $offset, 3);
}

sub get_uint6 {
  my ($data, $offset) = @_;
  return _get_bits($data, $offset, 6);
}

sub get_char6_pair {
  my ($data, $offset) = @_;

  my $pair;

  for (1 .. 2) {
    my ($byte, $next_offset) = get_uint6($data, $offset);

    $pair .= chr(ASCII_OFFSET + $byte);

    $offset = $next_offset;
  }

  return wantarray ? ($pair, $offset) : $pair;
}

sub get_uint12 {
  my ($data, $offset) = @_;
  return _get_bits($data, $offset, 12);
}

sub get_uint16 {
  my ($data, $offset) = @_;
  return _get_bits($data, $offset, 16);
}

sub get_uint36 {
  my ($data, $offset) = @_;
  return _get_bits($data, $offset, 36);
}

# General bit extractor that handles cross-byte boundaries efficiently.
# Since TCF is MSB-first, we can extract bytes, join them into a large
# integer, and then shift/mask.
sub _get_bits {
  my ($data, $offset, $nbits) = @_;

  my $byte_start = $offset >> 3;
  my $bit_start  = $offset & 7;
  my $byte_end   = ($offset + $nbits - 1) >> 3;
  my $num_bytes  = $byte_end - $byte_start + 1;

  croak "index out of bounds on offset $offset: can't read $nbits" if ($byte_end >= length($data));

  my $raw = substr($data, $byte_start, $num_bytes);
  my $val;

  # Unpack into a native integer and shift.
  # For up to 36 bits, we might need up to 6 bytes if it spans boundaries.
  if ($CAN_FORCE_BIG_ENDIAN) {
    if ($num_bytes == 1) {
      $val = unpack("C", $raw);
    }
    elsif ($num_bytes == 2) {
      $val = unpack("n", $raw);
    }
    elsif ($num_bytes == 3) {
      $val = unpack("N", "\0" . $raw);
    }
    elsif ($num_bytes == 4) {
      $val = unpack("N", $raw);
    }
  }

  if (!defined($val) && $num_bytes <= 8) {
    if ($CAN_PACK_QUADS) {
      my $padding = "\0" x (8 - $num_bytes);
      $val = unpack("Q>", $padding . $raw);
    }
    else {
      $val = Math::BigInt->new("0x" . unpack("H*", $raw));
    }
  }

  # Shift right to remove trailing bits of the last byte
  my $bits_in_buffer = $num_bytes << 3;
  my $right_shift    = $bits_in_buffer - $bit_start - $nbits;

  if (ref $val) {
    $val >>= $right_shift if $right_shift > 0;
    my $mask = Math::BigInt->new(1) << $nbits;
    $mask -= 1;
    $val &= $mask;
    return wantarray ? ($val->numify, $offset + $nbits) : $val->numify;
  }
  else {
    $val >>= $right_shift if $right_shift > 0;
    my $mask = (1 << $nbits) - 1;
    $val &= $mask;
    return wantarray ? ($val, $offset + $nbits) : $val;
  }
}

# Remove legacy helpers that worked on bitstrings

1;
__END__

=head1 NAME

GDPR::IAB::TCFv2::BitUtils - TCF v2.3 bit-level decoding utilities
 
=head1 SYNOPSIS
    use GDPR::IAB::TCFv2::BitUtils qw<is_set get_uint16>;

    my $data = '...'; # raw binary data
    
    my $max_vendor_id_consent = get_uint16($data, 213);
    my $is_service_specific   = is_set( $data, 138 );

=head2 get_uint2

Receive two parameters: data and bit offset.

Will fetch 2 bits from data since bit offset and convert it to an unsigned int.

    my $value = get_uint2( $data, $offset );

=head2 get_uint3

Receive two parameters: data and bit offset.

Will fetch 3 bits from data since bit offset and convert it to an unsigned int.

    my $segment_type = get_uint3( $data, 0 );

=head2 get_uint6

Receive two parameters: data and bit offset.

Will fetch 6 bits from data since bit offset and convert it to an unsigned int.

    my $version = get_uint6( $data, 0 );

=head2 get_char6_pair

Receives the data and bit offset.

Reads two consecutive 6-bit values starting at C<$offset>, increments each
by the ASCII value of the letter C<A>, and returns the resulting two-letter
string. Used to decode the C<consent_language> and C<publisher_country_code>
fields of the TCF v2 core string.

    my $consent_language = get_char6_pair($data, 108); # returns two letter country encoded as ISO_639-1

=head2 get_uint12

Receives the data and bit offset.

Will fetch 12 bits from data since bit offset and convert it to an unsigned int (short).

    my $cmp_id = get_uint12( $data, 78 );

=head2 get_uint16

Receives the data and bit offset.

Will fetch 16 bits from data since bit offset and convert it to an unsigned int (short).

    my $max_vendor_id_consent = get_uint16( $data, 213 );

=head2 get_uint36

Receives the data and bit offset.

Will fetch 36 bits from data since bit offset and convert it to an unsigned int (long).

    my $deciseconds = get_uint36( $data, 6 );
    my $created = $deciseconds/10;

