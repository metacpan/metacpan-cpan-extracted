package GDPR::IAB::TCFv2::BitField;
use strict;
use warnings;
use integer;
use bytes;

use GDPR::IAB::TCFv2::BitUtils qw<is_set>;
use Carp                       qw<croak>;

sub Parse {
    my ( $klass, %args ) = @_;

    croak "missing 'data'"      unless defined $args{data};
    croak "missing 'data_size'" unless defined $args{data_size};
    croak "missing 'max_id'"
      unless defined $args{max_id};

    croak "missing 'options'"      unless defined $args{options};
    croak "missing 'options.json'" unless defined $args{options}->{json};

    my $data      = $args{data};
    my $data_size = $args{data_size};
    my $offset    = 0;
    my $max_id    = $args{max_id};
    my $options   = $args{options};

    # add 7 to force rounding to next integer value
    my $bytes_required = ( $max_id + 7 ) / 8;

    croak
      "a BitField for $max_id requires a consent string of $bytes_required bytes. This consent string had $data_size"
      if $data_size < $bytes_required;

    my $self = {
        data    => substr( $data, $offset, $max_id ),
        max_id  => $max_id,
        options => $options,
    };

    bless $self, $klass;

    return ( $self, $offset + $max_id );
}

sub max_id {
    my $self = shift;

    return $self->{max_id};
}

sub contains {
    my ( $self, $id ) = @_;

    croak "invalid vendor id $id: must be positive integer bigger than 0"
      if $id < 1;

    return if $id > $self->{max_id};

    return is_set( $self->{data}, $id - 1 );
}

sub TO_JSON {
    my $self = shift;

    my @data = split //, $self->{data};

    if ( !!$self->{options}->{json}->{compact} ) {
        return [ grep { $data[ $_ - 1 ] } 1 .. $self->{max_id} ];
    }

    my ( $false, $true ) = @{ $self->{options}->{json}->{boolean_values} };

    if ( !!$self->{options}->{json}->{verbose} ) {
        return { map { $_ => $data[ $_ - 1 ] ? $true : $false }
              1 .. $self->{max_id} };
    }

    return {
        map  { $_ => $true }
        grep { $data[ $_ - 1 ] } 1 .. $self->{max_id}
    };
}

1;
__END__

=head1 NAME

GDPR::IAB::TCFv2::BitField - Transparency & Consent String version 2 bitfield parser

=head1 SYNOPSIS

    my $data = unpack "B*", decode_base64url('tcf v2 consent string base64 encoded');
    
    my $max_id_consent = << get 16 bits from $data offset 213 >>

    my $bit_field = GDPR::IAB::TCFv2::BitField->Parse(
        data      => substr($data, OFFSET),
        data_size => length($data),
        max_id    => $max_id_consent,
        options   => { json => ... },
    );

    say "bit field contains id 284" if $bit_field->contains(284);

=head1 CONSTRUCTOR

Constructor C<Parse> receives an hash of 4 parameters: 

=over

=item *

Key C<data> is the binary data

=item *

Key C<data_size> is the original binary data size

=item *

Key C<max_id> is the max id (used to validate the ranges if all data is between 1 and  C<max_id>)

=item *

Key C<options> is the L<GDPR::IAB::TCFv2> options (includes the C<json> field to modify the L</TO_JSON> method output.

=back

=head1 METHODS

=head2 contains

Return the vendor id bit status (if enable or not) from the bit field.
Will return false if id is bigger than max vendor id.

    my $ok = $bit_field->contains(284);

=head2 max_id

Returns the max vendor id.

=head2 all

Returns an array of all vendors mapped with the bit enabled.

=head2 TO_JSON

By default it returns an hashref mapping id to a boolean, that represent if the id is active or not in the bitfield.

The json option C<verbose> controls if all ids between 1 to L</max_id> will be present on the C<json> or only the ones that are true.

The json option C<compact> change the response, will return an arrayref of all ids active on the bitfield.
