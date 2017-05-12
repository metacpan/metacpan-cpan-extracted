package Lab::Moose::Instrument::SCPI::Sense::Sweep;

use Moose::Role;
use Lab::Moose::Instrument::Cache;
use Lab::Moose::Instrument
    qw/validated_channel_getter validated_channel_setter/;
use MooseX::Params::Validate;
use Carp;

use namespace::autoclean;

our $VERSION = '3.542';

=head1 NAME

Lab::Moose::Instrument::SCPI::Sense::Sweep - Role for SCPI SENSe:SWEep
subsystem.

=head1 METHODS

=head2 sense_sweep_points_query

=head2 sense_sweep_points

Query/Set the number of points in the sweep.

=cut

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

=head2 sense_sweep_count_query

=head2 sense_sweep_count

Query/Set the number of sweeps initiated by a trigger (like INIT).

=cut

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

1;
