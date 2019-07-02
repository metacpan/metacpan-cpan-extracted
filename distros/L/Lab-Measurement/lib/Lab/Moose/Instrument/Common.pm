package Lab::Moose::Instrument::Common;
#ABSTRACT: Role for common commands declared mandatory by IEEE 488.2
$Lab::Moose::Instrument::Common::VERSION = '3.682';
use Moose::Role;
use MooseX::Params::Validate;

use Lab::Moose::Instrument qw/
    validated_getter
    validated_setter
    validated_no_param_setter
    /;
use Carp;

use namespace::autoclean;


sub cls {
    my ( $self, %args ) = validated_no_param_setter( \@_ );
    return $self->write( command => '*CLS', %args );
}


sub idn {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->query( command => '*IDN?', %args );
}


sub idn_manufacturer {
    my ( $self, %args ) = validated_getter( \@_ );
    my $i=$self->query( command => '*IDN?', %args );
    my ($man, $mod, $ser, $fir) = split /,/, $i, 4;
    return $man;
}


sub idn_model {
    my ( $self, %args ) = validated_getter( \@_ );
    my $i=$self->query( command => '*IDN?', %args );
    my ($man, $mod, $ser, $fir) = split /,/, $i, 4;
    return $mod;
}


sub idn_serial {
    my ( $self, %args ) = validated_getter( \@_ );
    my $i=$self->query( command => '*IDN?', %args );
    my ($man, $mod, $ser, $fir) = split /,/, $i, 4;
    return $ser;
}


sub idn_firmware {
    my ( $self, %args ) = validated_getter( \@_ );
    my $i=$self->query( command => '*IDN?', %args );
    my ($man, $mod, $ser, $fir) = split /,/, $i, 4;
    return $fir;
}


sub opc {
    my ( $self, %args ) = validated_no_param_setter( \@_ );
    return $self->write( command => '*OPC', %args );
}


sub opc_query {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->query( command => '*OPC?', %args );
}


sub opc_sync {
    my ( $self, %args ) = validated_getter( \@_ );
    my $one = $self->opc_query(%args);
    if ( $one ne '1' ) {
        croak "OPC query did not return '1'";
    }
    return $one;
}


sub rst {
    my ( $self, %args ) = validated_no_param_setter( \@_ );
    return $self->write( command => '*RST', %args );
}


sub wai {
    my ( $self, %args ) = validated_no_param_setter( \@_ );
    return $self->write( command => '*WAI', %args );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::Common - Role for common commands declared mandatory by IEEE 488.2

=head1 VERSION

version 3.682

=head1 METHODS

=head2 cls

Send I<*CLS> command.

=head2 idn

Return result of I<*IDN?> query.

=head2 idn_manufacturer

Returns the manufacturer field from an  I<*IDN?> query.

=head2 idn_model

Returns the model field from an  I<*IDN?> query.

=head2 idn_serial

Returns the serial number field from an  I<*IDN?> query.

=head2 idn_firmware

Returns the firmware version field from an  I<*IDN?> query.

=head2 opc

Send I<*OPC> command.

=head2 opc_query

Return result of I<*OPC?> query.

=head2 opc_sync

Perform C<opc_query> and croak if it does not return '1'. Make sure to provide
a sufficient timeout.

=head2 rst

Send I<*RST> command.

=head2 wai

Send I<*WAI> command.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2016       Simon Reinhardt
            2017       Andreas K. Huettel, Simon Reinhardt
            2018       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
