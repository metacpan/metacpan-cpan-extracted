package Lab::Moose::Instrument::SCPI::Sense::Power;
#ABSTRACT: Role for the SCPI SENSe:POWer subsystem
$Lab::Moose::Instrument::SCPI::Sense::Power::VERSION = '3.682';
use Moose::Role;
use Lab::Moose::Instrument::Cache;
use Lab::Moose::Instrument
    qw/validated_getter validated_setter/;
use MooseX::Params::Validate;
use Carp;

use namespace::autoclean;


cache sense_power_rf_attenuation => ( getter => 'sense_power_rf_attenuation_query' );

sub sense_power_rf_attenuation_query {
    my ( $self, %args ) = validated_getter( \@_ );

    return $self->cached_sense_power_rf_attenuation(
        $self->query( command => "SENS:POW:RF:ATT?", %args ) );
}

sub sense_power_rf_attenuation {
    my ( $self, $value, %args ) = validated_setter( \@_ );

    $self->write( command => "SENS:POW:RF:ATT $value", %args );
    $self->cached_sense_power_rf_attenuation($value);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::SCPI::Sense::Power - Role for the SCPI SENSe:POWer subsystem

=head1 VERSION

version 3.682

=head1 METHODS

=head2 sense_power_rf_attenuation_query

=head2 sense_power_rf_attenuation

Query/Set the input attenuation.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2018       Eugeniy E. Mikhailov


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
