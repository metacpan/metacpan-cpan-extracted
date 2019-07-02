package Lab::Moose::Instrument::SCPI::Sense::Sweep;
#ABSTRACT: Role for the SCPI SENSe:SWEep subsystem
$Lab::Moose::Instrument::SCPI::Sense::Sweep::VERSION = '3.682';
use Moose::Role;
use Lab::Moose::Instrument::Cache;
use Lab::Moose::Instrument
    qw/validated_channel_getter validated_channel_setter/;
use MooseX::Params::Validate;
use Carp;

use namespace::autoclean;


cache sense_sweep_points => ( getter => 'sense_sweep_points_query' );

sub sense_sweep_points_query {
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );

    return $self->cached_sense_sweep_points(
        $self->query( command => "SENS${channel}:SWE:POIN?", %args ) );
}

sub sense_sweep_points {
    my ( $self, $channel, $value, %args ) = validated_channel_setter( \@_ );

    $self->write( command => "SENS${channel}:SWE:POIN $value", %args );
    $self->cached_sense_sweep_points($value);
}


cache sense_sweep_count => ( getter => 'sense_sweep_count_query' );

sub sense_sweep_count_query {
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );
    return $self->cached_sense_sweep_count(
        $self->query( command => "SENS${channel}:SWE:COUN?", %args ) );
}

sub sense_sweep_count {
    my ( $self, $channel, $value, %args ) = validated_channel_setter( \@_ );

    $self->write( command => "SENS${channel}:SWE:COUN $value", %args );
    $self->cached_sense_sweep_count($value);
}


cache sense_sweep_time => ( getter => 'sense_sweep_time_query' );

sub sense_sweep_time_query {
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );
    return $self->cached_sense_sweep_time(
        $self->query( command => "SENS${channel}:SWE:TIME?", %args ) );
}

sub sense_sweep_time {
    my ( $self, $channel, $value, %args ) = validated_channel_setter( \@_ );

    $self->write( command => "SENS${channel}:SWE:TIME $value", %args );
    $self->cached_sense_sweep_time($value);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::SCPI::Sense::Sweep - Role for the SCPI SENSe:SWEep subsystem

=head1 VERSION

version 3.682

=head1 METHODS

=head2 sense_sweep_points_query

=head2 sense_sweep_points

Query/Set the number of points in the sweep.

=head2 sense_sweep_count_query

=head2 sense_sweep_count

Query/Set the number of sweeps initiated by a trigger (like INIT).

=head2 sense_sweep_time_query

=head2 sense_sweep_time

Query/Set the sweep time in which the spectrum analyzer sweeps the required frequency range.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2016       Simon Reinhardt
            2017       Andreas K. Huettel, Simon Reinhardt
            2018       Eugeniy E. Mikhailov


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
