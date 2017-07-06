package Lab::Moose::Instrument::SCPIBlock;
#Dist::Zilla: +PodWeaver
#ABSTRACT: Role for handling SCPI/IEEE 488.2 block data
$Lab::Moose::Instrument::SCPIBlock::VERSION = '3.552';
use Moose::Role;
use MooseX::Params::Validate;

use Lab::Moose::Instrument 'precision_param';

use Carp;

use namespace::autoclean;

with qw/
    Lab::Moose::Instrument::SCPI::Sense::Sweep
    Lab::Moose::Instrument::SCPI::Format
    /;


sub block_to_array {
    my ( $self, %args ) = validated_hash(
        \@_,
        binary => { isa => 'Str' },
        precision_param(),
        ,
    );

    my $precision = delete $args{precision};
    my $binary    = delete $args{binary};

    if ( substr( $binary, 0, 1 ) ne '#' ) {
        croak 'does not look like binary data';
    }

    my $num_digits = substr( $binary, 1, 1 );
    my $num_bytes  = substr( $binary, 2, $num_digits );
    my $expected_length = $num_bytes + $num_digits + 2;

    # $binary might have a trailing newline, so do not check for equality.
    if ( length $binary < $expected_length ) {
        croak "incomplete data: expected_length: $expected_length,"
            . " received length: ", length $binary;
    }

    my @floats = unpack(
        $precision eq 'single' ? 'f*' : 'd*',
        substr( $binary, 2 + $num_digits, $num_bytes )
    );

    return \@floats;

}


sub set_data_format_precision {
    my ( $self, %args ) = validated_hash(
        \@_,
        precision_param(),
    );

    my $precision = delete $args{precision};
    my $length    = $precision eq 'single' ? 32 : 64;
    my $format    = $self->cached_format_data();

    if ( $format->[0] ne 'REAL' || $format->[1] != $length ) {
        carp "setting data format: REAL, $length";
        $self->format_data( format => 'REAL', length => $length );
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::SCPIBlock - Role for handling SCPI/IEEE 488.2 block data

=head1 VERSION

version 3.552

=head1 DESCRIPTION

So far, only definite length floating point data of type 'REAL' is
supported.

See "8.7.9 <DEFINITE LENGTH ARBITRARY BLOCK RESPONSE DATA>" in IEEE 488.2.

=head1 METHODS

=head2 block_to_array

 my $array_ref = $self->block_to_array(
     binary => "#232${bytes}";
     precision => 'double'
 );

Convert block data to arrayref, where the binary block holds floating point
values in native byte-order.

=head2 set_data_format_precision

 $self->set_data_format_precision( precision => 'double' );

Set used floating point type. Has to be 'single' (default) or 'double'.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by the Lab::Measurement team.
  Copyright 2016       Andreas K. Huettel, Simon Reinhardt
            2017       Andreas K. Huettel

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
