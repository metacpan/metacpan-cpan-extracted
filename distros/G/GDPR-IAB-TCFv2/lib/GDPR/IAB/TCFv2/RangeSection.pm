package GDPR::IAB::TCFv2::RangeSection;
use strict;
use warnings;
use integer;
use bytes;

use GDPR::IAB::TCFv2::BitUtils qw<is_set get_uint12 get_uint16>;
use GDPR::IAB::TCFv2::RangeConsent;
use Carp qw<croak>;

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

    croak
      "a BitField for vendor consent strings using RangeSections require at least 31 bytes. Got $data_size"
      if $data_size < 32;

    my $num_entries = get_uint12( $data, $start_bit );

    my $current_offset = $start_bit + 12;

    my @consents;

    foreach my $i ( 1 .. $num_entries ) {
        my ( $consent, $bits_consumed ) = _parse_range_consent(
            $data, $current_offset,
            $vendor_bits_required
        );

        push @consents, $consent;

        $current_offset += $bits_consumed;
    }

    my $self = {
        consents             => \@consents,
        vendor_bits_required => $vendor_bits_required,
        _current_offset      => $current_offset,
    };

    bless $self, $klass;

    return $self;
}

sub _parse_range_consent {
    my ( $data, $initial_bit, $max_vendor_id ) = @_;

    my $data_size = length($data);

    croak
      "bit $initial_bit was suppose to start a new range entry, but the consent string was only $data_size bytes long"
      if $data_size <= $initial_bit / 8;

    # If the first bit is set, it's a Range of IDs
    if ( is_set $data, $initial_bit ) {
        my $start = get_uint16( $data, $initial_bit + 1 );
        my $end   = get_uint16( $data, $initial_bit + 17 );

        croak
          "bit $initial_bit range entry exclusion ends at $end, but the max vendor ID is $max_vendor_id"
          if $end > $max_vendor_id;

        return GDPR::IAB::TCFv2::RangeConsent->new(
            start => $start,
            end   => $end
          ),
          33;
    }

    my $vendor_id = get_uint16( $data, $initial_bit + 1 );

    croak
      "bit $initial_bit range entry excludes vendor $vendor_id, but only vendors [1, $max_vendor_id] are valid"
      if $vendor_id > $max_vendor_id;

    return GDPR::IAB::TCFv2::RangeConsent->new(
        start => $vendor_id,
        end   => $vendor_id
      ),
      17;
}

sub current_offset {
    my $self = shift;

    return $self->{_current_offset};
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

    foreach my $c ( @{ $self->{consents} } ) {
        return 1 if $c->contains($id);
    }

    return 0;
}

1;
__END__

=head1 NAME

GDPR::IAB::TCFv2::RangeSection - Transparency & Consent String version 2 range section parser

=head1 SYNOPSIS

    my $data = unpack "B*", decode_base64url('tcf v2 consent string base64 encoded');
    
    my $max_vendor_id_consent = << get 16 bits from $data offset 213 >>

    my $range_section = GDPR::IAB::TCFv2::RangeSection->new(
        data                 => $data,
        start_bit            => 230, # offset for vendor consents
        vendor_bits_required => $max_vendor_id_consent
    );

    if $range_section->contains(284) { ... }

=head1 CONSTRUCTOR

Receive 3 parameters: data (as sequence of bits), start bit offset and vendor bits required (max vendor id).

Will die if any parameter is missing.

Will die if data does not contain all bits required.

Will die if the range sections are malformed.

=head1 METHODS

=head2 contains

Return the vendor id bit status (if enable or not) from one of the range sections.

Will return false if id is bigger than max vendor id.

    my $ok = $range_section->contains(284);

=head2 max_vendor_id

Returns the max vendor id.
