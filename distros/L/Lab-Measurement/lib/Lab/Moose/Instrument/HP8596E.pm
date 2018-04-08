package Lab::Moose::Instrument::HP8596E;
$Lab::Moose::Instrument::HP8596E::VERSION = '3.624';
#ABSTRACT: HP8596E Spectrum Analyzer

use 5.010;

use PDL::Core qw/pdl cat/;

use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Params::Validate;
use Lab::Moose::Instrument qw/
    timeout_param
    precision_param
    validated_getter
    validated_channel_getter
    validated_channel_setter
    /;
use Lab::Moose::Instrument::Cache;
use Carp;
use namespace::autoclean;

extends 'Lab::Moose::Instrument';

with qw(
    Lab::Moose::Instrument::SCPI::Sense::Frequency
    Lab::Moose::Instrument::SCPI::Sense::Sweep
    Lab::Moose::Instrument::SCPI::Sense::Bandwidth
    Lab::Moose::Instrument::SCPI::Display::Window
    Lab::Moose::Instrument::SCPI::Unit
);

#    Lab::Moose::Instrument::Common
#    Lab::Moose::Instrument::SCPI::Format

#    Lab::Moose::Instrument::SCPI::Initiate

#    Lab::Moose::Instrument::SCPIBlock

sub BUILD {
    my $self = shift;

    #    $self->clear();
    #    $self->cls();
}

##### This device predates creation of SCPI commands (introduced in 1999), so we fake them

sub idn {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->query( command => '*ID?', %args );
}

### Sense:Frequency emulation
sub sense_frequency_start_query {
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );

    return $self->cached_sense_frequency_start(
        $self->query( command => "FA?", %args ) );
}

sub sense_frequency_start {
    my ( $self, $channel, $value, %args ) = validated_channel_setter( \@_ );
    $self->write(
        command => sprintf( "FA %.17g", $value ),
        %args
    );
    $self->cached_sense_frequency_start($value);
}

sub sense_frequency_stop_query {
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );

    return $self->cached_sense_frequency_stop(
        $self->query( command => "FB?", %args ) );
}

sub sense_frequency_stop {
    my ( $self, $channel, $value, %args ) = validated_channel_setter( \@_ );
    $self->write(
        command => sprintf( "FB %.17g", $value ),
        %args
    );
    $self->cached_sense_frequency_stop($value);
}

### Sense:Sweep:Points emulation

sub sense_sweep_points_query {
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );

    return $self->cached_sense_sweep_count(401);    # hard wired
}

sub sense_sweep_points {
    my ( $self, $channel, $value, %args ) = validated_channel_setter( \@_ );

    $value = 401;                                   #hardwired
    $self->cached_sense_sweep_points($value);
}

### Sense:Sweep:Count  emulation

sub sense_sweep_count_query {
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );
    return $self->cached_sense_sweep_count(1);      # hardwired
}

sub sense_sweep_count {
    my ( $self, $channel, $value, %args ) = validated_channel_setter( \@_ );

    $value = 1;                                     # hard wired
    $self->cached_sense_sweep_count($value);
}

### Sense:Bandwidth:Resolution emulation

sub sense_bandwidth_resolution_query {
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );

    return $self->cached_sense_bandwidth_resolution(
        $self->query( command => "RB?", %args ) );
}

sub sense_bandwidth_resolution {
    my ( $self, $channel, $value, %args ) = validated_channel_setter(
        \@_,
        value => { isa => 'Num' }
    );
    $self->write(
        command => sprintf( "RB %.17g", $value ),
        %args
    );
    $self->cached_sense_bandwidth_resolution($value);
}

sub sense_bandwidth_video_query {
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );

    return $self->cached_sense_bandwidth_video(
        $self->query( command => "VB?", %args ) );
}

sub sense_bandwidth_video {
    my ( $self, $channel, $value, %args ) = validated_channel_setter(
        \@_,
        value => { isa => 'Num' }
    );
    $self->write(
        command => sprintf( "VB %.17g", $value ),
        %args
    );
    $self->cached_sense_bandwidth_video($value);
}

### Sense:Sweep:Time

sub sense_sweep_time_query {
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );
    return $self->cached_sense_sweep_count(
        $self->query( command => "ST?", %args ) );
}

sub sense_sweep_time {
    my ( $self, $channel, $value, %args ) = validated_channel_setter( \@_ );

    $self->write( command => "ST $value", %args );
    $self->cached_sense_sweep_count($value);
}

### Display:Window:Trace:Y:Scale:Rlevel

sub display_window_trace_y_scale_rlevel_query {
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );

    return $self->cached_display_window_trace_y_scale_rlevel(
        $self->query( command => "RL?", %args ) );
}

sub display_window_trace_y_scale_rlevel {
    my ( $self, $channel, $value, %args ) = validated_channel_setter( \@_ );
    $self->write(
        command => sprintf( "RL %.17g", $value ),
        %args
    );
    $self->cached_display_window_trace_y_scale_rlevel($value);
}

### Unit:Power

sub unit_power_query {
    my ( $self, %args ) = validated_getter( \@_ );

    return $self->cached_unit_power(
        $self->query( command => "AUNITS?", %args ) );
}

sub unit_power {
    my ( $self, $channel, $value, %args ) = validated_channel_setter( \@_ );

    # allowed values are DBM, DBMV, DBUV, V, W
    $self->write(
        command => sprintf( "AUNITS %s", $value ),
        %args
    );
    $self->cached_unit_power($value);
}

### Trace/Data emulation
sub get_spectrum {
    my ( $self, %args ) = validated_hash(
        \@_,
        timeout_param(),
        trace => { isa => 'Int', default => 1 },
    );

    my $trace = delete $args{trace};

    if ( $trace < 1 || $trace > 3 ) {
        croak "trace has to be in (1..3)";
    }

    # convert trace number to name 1->A, 2->B, ...
    if ( $trace == 1 ) {
        $trace = 'A';
    }
    elsif ( $trace == 2 ) {
        $trace = 'B';
    }
    elsif ( $trace == 3 ) {
        $trace = 'C';
    }

    # 'TDF P' switches output format to the human readable (ascii)
    # number representation. Numbers are separated by commas
    my $reply = $self->query(
        command => "TDF P; TR$trace?",
        %args
    );
    my @dat = split( /,/, $reply );

    my @freq_array = $self->sense_frequency_linear_array();

    return cat( ( pdl @freq_array ), ( pdl @dat ) );

}

__PACKAGE__->meta()->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::HP8596E - HP8596E Spectrum Analyzer

=head1 VERSION

version 3.624

=head1 SYNOPSIS

 my $data = $hp->get_spectrum(trace=>1, timeout => 10);

=head1 NAME

Lab::Moose::Instrument::HP8596E - HP Spectrum Analyzer

=head1 VERSION

version 3.621

=head1 METHODS

This driver implements the following high-level method:

=head2 get_spectrum

 $data = $hp->get_spectrum(timeout => 10, trace => 2);

Perform a single sweep and return the resulting spectrum as a 2D PDL:

 [
  [freq1,  freq2,  freq3,  ...,  freqN],
  [power1, power2, power3, ..., powerN],
 ]

I.e. the first dimension runs over the sweep points.

This method accepts a hash with the following options:

=over

=item B<timeout>

timeout for the sweep operation. If this is not given, use the connection's
default timeout.

=item B<trace>

number of the trace (1..3). Defaults to 1.

=back

=head1 SEE ALSO

This driver modeled closely to RS_FSV (see L<Lab::Moose::Instrument::RS_FSV>) and should perform similar functions.

In particular commands from the following SCPI subsystems are implemented

L<Lab::Moose::Instrument::SCPI::Sense::Frequency>,
L<Lab::Moose::Instrument::SCPI::Sense::Sweep>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by the Lab::Measurement team; in detail:

  Copyright 2018       Eugeniy E. Mikhailov


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
