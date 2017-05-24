package Lab::Moose::Instrument::SCPI::Sense::Average;

use Moose::Role;
use Lab::Moose::Instrument::Cache;
use Lab::Moose::Instrument
    qw/validated_channel_getter validated_channel_setter/;
use MooseX::Params::Validate;
use Carp;

use namespace::autoclean;

our $VERSION = '3.543';

cache sense_average_state => ( getter => 'sense_average_state_query' );

=head1 NAME

Lab::Moose::Instrument::SCPI::Sense::Average - Role for SCPI SENSe:AVERage
subsystem.

=head1 METHODS

=head2 sense_average_state_query

=head2 sense_average_state

Query/Set whether averaging is turned on/off.

=cut

sub sense_average_state_query {
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );

    return $self->cached_sense_average_state(
        $self->query( command => "SENS${channel}:AVER?", %args ) );
}

sub sense_average_state {
    my ( $self, $channel, $value, %args ) = validated_channel_setter( \@_ );
    $self->write( command => "SENS${channel}:AVER $value", %args );
    return $self->cached_sense_average_state($value);
}

=head2 sense_average_count_query

=head2 sense_average_count

Query/Set the number of measurements used for an average.

=cut

cache sense_average_count => (
    getter => 'sense_average_count_query',
    isa    => 'Int'
);

sub sense_average_count_query {
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );

    return $self->cached_sense_average_count(
        $self->query( command => "SENS${channel}:AVER:COUN?", %args ) );
}

sub sense_average_count {
    my ( $self, $channel, $value, %args ) = validated_channel_setter( \@_ );
    $self->write( command => "SENS${channel}:AVER:COUN $value", %args );
    return $self->cached_sense_average_count($value);
}

1;
