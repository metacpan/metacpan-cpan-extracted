package Lab::Moose::Instrument::SCPI::Sense::Frequency;

use Moose::Role;
use Lab::Moose::Instrument::Cache;
use Lab::Moose::Instrument
    qw/validated_channel_getter validated_channel_setter/;
use MooseX::Params::Validate;
use Carp;

use namespace::autoclean;

with 'Lab::Moose::Instrument::SCPI::Sense::Sweep';

our $VERSION = '3.543';

=head1 NAME

Lab::Moose::Instrument::SCPI::Sense::Frequency -  Role for SCPI SENSe:FREQuency
subsystem.

=head1 METHODS

=head2 sense_frequency_start_query

 my $freq = $self->sense_frequency_start_query();

Query the starting point of the frequency sweep.

=head2 sense_frequency_start

 $self->sense_frequency_start(value => 4e9);

Set the starting point of the frequency sweep.

=head2 sense_frequency_stop_query

=head2 sense_frequency_stop

Query and set the end point of the frequency sweep.

=cut

cache sense_frequency_start => ( getter => 'sense_frequency_start_query' );

sub sense_frequency_start_query {
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );

    return $self->cached_sense_frequency_start(
        $self->query( command => "SENS${channel}:FREQ:STAR?", %args ) );
}

sub sense_frequency_start {
    my ( $self, $channel, $value, %args ) = validated_channel_setter( \@_ );
    $self->write(
        command => sprintf( "SENS%s:FREQ:STAR %.17g", $channel, $value ),
        %args
    );
    $self->cached_sense_frequency_start($value);
}

cache sense_frequency_stop => ( getter => 'sense_frequency_stop_query' );

sub sense_frequency_stop_query {
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );

    return $self->cached_sense_frequency_stop(
        $self->query( command => "SENS${channel}:FREQ:STOP?", %args ) );
}

sub sense_frequency_stop {
    my ( $self, $channel, $value, %args ) = validated_channel_setter( \@_ );
    $self->write(
        command => sprintf( "SENS%s:FREQ:STOP %.17g", $channel, $value ),
        %args
    );
    $self->cached_sense_frequency_stop($value);
}

=head2 sense_frequency_linear_array

 my $arrayref = $self->sense_frequency_linear_array();

Helper method to get an arrayref of all points in the frequency sweep.
Does not provide a cached form, but will read it's input from cache.

=cut

sub sense_frequency_linear_array {
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );

    my $start      = $self->cached_sense_frequency_start();
    my $stop       = $self->cached_sense_frequency_stop();
    my $num_points = $self->cached_sense_sweep_points();

    my $num_intervals = $num_points - 1;

    if ( $num_intervals == 0 ) {

        # Return a single point.
        return [$start];
    }

    my @result;

    for my $i ( 0 .. $num_intervals ) {
        my $f = $start + ( $stop - $start ) * ( $i / $num_intervals );
        push @result, $f;
    }

    return \@result;
}

1;
