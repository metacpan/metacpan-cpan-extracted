package Lab::Moose::Instrument::SCPI::Sense::Function;

use Moose::Role;
use Lab::Moose::Instrument::Cache;
use Lab::Moose::Instrument
    qw/validated_channel_getter validated_channel_setter/;
use MooseX::Params::Validate;
use Carp;

use namespace::autoclean;

our $VERSION = '3.543';

=head1 NAME

Lab::Moose::Instrument::SCPI::Sense::Function - Role for SCPI SENSe:FUNCtion
subsystem.

=head1 METHODS

=head2 sense_function_query

=head2 sense_function

Query/Set the function used by the instrument.

=cut

cache sense_function => ( getter => 'sense_function_query' );

sub sense_function_query {
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );

    return $self->cached_sense_function(
        $self->query( command => "SENS${channel}:FUNC?", %args ) );
}

sub sense_function {
    my ( $self, $channel, $value, %args ) = validated_channel_setter( \@_ );

    $self->write( command => "SENS${channel}:FUNC $value", %args );
    return $self->cached_sense_function($value);
}

1;
