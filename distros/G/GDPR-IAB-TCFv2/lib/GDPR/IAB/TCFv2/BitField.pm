package GDPR::IAB::TCFv2::BitField;
use strict;
use warnings;
use integer;
use bytes;

use GDPR::IAB::TCFv2::BitUtils qw<is_set>;
use Carp                       qw<croak>;

sub new {
    my ( $klass, %args ) = @_;

    croak "missing 'data'"      unless defined $args{data};
    croak "missing 'start_bit'" unless defined $args{start_bit};
    croak "missing 'vendor_bits_required'"
      unless defined $args{vendor_bits_required};

    my $data                 = $args{data};
    my $start_bit            = $args{start_bit};
    my $vendor_bits_required = $args{vendor_bits_required};

    my $data_size = length($data);

    # add 7 to force rounding to next integer value
    my $bytes_required = ( $vendor_bits_required + $start_bit + 7 ) / 8;

    croak
      "a BitField for $vendor_bits_required requires a consent string of $bytes_required bytes. This consent string had $data_size"
      if $data_size < $bytes_required;

    my $self = {
        data                 => substr( $data, $start_bit ),
        vendor_bits_required => $vendor_bits_required,
    };

    bless $self, $klass;

    return $self;
}

sub max_vendor_id {
    my $self = shift;

    return $self->{vendor_bits_required};
}

sub contains {
    my ( $self, $id ) = @_;

    croak "invalid vendor id $id: must be positive integer bigger than 0"
      if $id < 1;

    return if $id > $self->{vendor_bits_required};

    return is_set( $self->{data}, $id - 1 );
}

1;
__END__

=head1 NAME

GDPR::IAB::TCFv2::BitField - Transparency & Consent String version 2 bitfield parser

=head1 SYNOPSIS

    my $data = unpack "B*", decode_base64url('tcf v2 consent string base64 encoded');
    
    my $max_vendor_id_consent = << get 16 bits from $data offset 213 >>

    my $bit_field = GDPR::IAB::TCFv2::BitField->new(
        data                 => $data,
        start_bit            => 230, # offset for vendor consents
        vendor_bits_required => $max_vendor_id_consent
    );

    if $bit_field->contains(284) { ... }

=head1 CONSTRUCTOR

Receive 3 parameters: data (as sequence of bits), start bit offset and vendor bits required (max vendor id).

Will die if any parameter is missing.

Will die if data does not contain all bits required.

=head1 METHODS

=head2 contains

Return the vendor id bit status (if enable or not) from the bit field.
Will return false if id is bigger than max vendor id.

    my $ok = $bit_field->contains(284);

=head2 max_vendor_id

Returns the max vendor id.
