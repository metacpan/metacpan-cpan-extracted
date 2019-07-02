package Lab::Moose::Instrument::SpectrumAnalyzer;
$Lab::Moose::Instrument::SpectrumAnalyzer::VERSION = '3.682';
#ABSTRACT: Role of Generic Spectrum Analyzer for Lab::Moose::Instrument

use 5.010;

use PDL::Core qw/pdl cat nelem/;

use Carp;
use POSIX 'strftime';
use Moose::Role;
use MooseX::Params::Validate;
use Lab::Moose::Instrument qw/
    timeout_param
    precision_param
    validated_getter
    validated_setter
    validated_channel_getter
    validated_channel_setter
    /;

#use Lab::Moose::Instrument::Cache;

requires qw(
    sense_frequency_start_query
    sense_frequency_start
    sense_frequency_stop_query
    sense_frequency_stop
    sense_sweep_points_query
    sense_sweep_points
    sense_sweep_count_query
    sense_sweep_count
    sense_bandwidth_resolution_query
    sense_bandwidth_resolution
    sense_bandwidth_video_query
    sense_bandwidth_video
    sense_sweep_time_query
    sense_sweep_time
    display_window_trace_y_scale_rlevel_query
    display_window_trace_y_scale_rlevel
    unit_power_query
    unit_power
    sense_power_rf_attenuation_query
    sense_power_rf_attenuation
    validate_trace_param
);

with 'Lab::Moose::Instrument::DisplayXY';


has 'capable_to_query_number_of_X_points_in_hardware' => (
    is       => 'rw',
    isa      => 'Bool',
    required => 1,
    default  => 1,
);

has 'capable_to_set_number_of_X_points_in_hardware' => (
    is       => 'rw',
    isa      => 'Bool',
    required => 1,
    default  => 1,
);

has 'hardwired_number_of_X_points' => (
    is        => 'rw',
    isa       => 'Int',
    predicate => 'has_hardwired_number_of_X_points',
);


sub sense_sweep_points_from_traceY_query {

    # quite a lot of hardware does not report it, so we deduce it from Y-trace data
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );
    return nelem( $self->get_traceY(%args) );
}

sub get_Xpoints_number {
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );
    if ( $self->has_hardwired_number_of_X_points ) {

        #carp("using hardwired number of points: " . $self->hardwired_number_of_X_points . "\n" );
        return $self->cached_sense_sweep_points(
            $self->hardwired_number_of_X_points );
    }
    if ( $self->capable_to_query_number_of_X_points_in_hardware ) {

        #carp("using hardware capabilities to detect number of points in a sweep\n");
        return $self->sense_sweep_points_query(%args);
    }

    #carp("trying heuristic to detect number of points in a sweep\n");
    return $self->cached_sense_sweep_points(
        $self->sense_sweep_points_from_traceY_query(%args) );
}


sub get_StartX {
    my ( $self, %args ) = @_;
    return $self->cached_sense_frequency_start();
}

sub get_StopX {
    my ( $self, %args ) = @_;
    return $self->cached_sense_frequency_stop();
}


sub get_traceY {

    # grab what is on display for a given trace
    my ( $self, %args ) = validated_hash(
        \@_,
        timeout_param(),
        precision_param(),
        trace => { isa => 'Int', default => 1 },
    );

    my $precision = delete $args{precision};
    my $trace     = delete $args{trace};

    $trace = $self->validate_trace_param($trace);

    # Switch to binary trace format
    $self->set_data_format_precision( precision => $precision );

    # above is equivalent to cached call
    # $self->format_data( format => 'Real', length => 32 );

    # Get data.
    my $binary = $self->binary_query(
        command => "TRAC? TRACE$trace",
        %args
    );
    my $traceY = pdl $self->block_to_array(
        binary    => $binary,
        precision => $precision
    );
    return $traceY;
}

sub get_traceXY {
    my ( $self, %args ) = @_;

    my $traceY = $self->get_traceY(%args);

    # number of sweep points is known from the length of traceY
    # so we set it to avoid extra call to get_traceY
    if ( !$self->capable_to_query_number_of_X_points_in_hardware ) {

        #carp("setting cache with sweep number of points via heuristic");
        $self->cached_sense_sweep_points( nelem($traceY) );
    }
    my $traceX = $self->get_traceX(%args);

    return cat( $traceX, $traceY );
}

sub get_NameX {
    my ( $self, %args ) = @_;
    return 'Frequency';
}

sub get_UnitX {
    my ( $self, %args ) = @_;
    return 'Hz';
}

sub get_NameY {
    my ( $self, %args ) = @_;
    my $name;
    my $unitY = $self->get_UnitY(%args);
    if    ( $unitY =~ qr/dbm|w/i )       { $name = 'Power'; }
    elsif ( $unitY =~ qr/dbmv|dbuv|w/i ) { $name = 'Amplitude'; }
    else { $name = 'Unknown'; carp( "Unknow Y unit " . $unitY ); }
    return $name;
}

sub get_UnitY {
    my ( $self, %args ) = @_;
    return $self->unit_power_query(%args);
}

sub get_loggable_state {
    my ( $self, %args ) = @_;

    my %state;
    $state{Id}        = $self->idn(%args);
    $state{date}      = strftime( '%Y-%m-%dT%H:%M:%S', localtime() );
    $state{VBW}       = $self->sense_bandwidth_video_query(%args);
    $state{RBW}       = $self->sense_bandwidth_resolution_query(%args);
    $state{SweepTime} = $self->sense_sweep_time_query(%args);
    $state{NameX}     = $self->get_NameX(%args);
    $state{UnitX}     = $self->get_UnitX(%args);
    $state{NameY}     = $self->get_NameY(%args);
    $state{UnitY}     = $self->get_UnitY(%args);
    $state{RefLevel}  = $self->display_window_trace_y_scale_rlevel_query(%args);
    $state{InputAttenuation}  = $self->sense_power_rf_attenuation_query(%args);

    return %state;
}

sub get_log_header {
    my ( $self, %args ) = @_;
    my %state = $self->get_loggable_state(%args);

    my @header_names = qw/
        Id
	date
       	VBW
       	RBW
       	SweepTime
       	NameX
       	UnitX
       	NameY
       	UnitY
       	RefLevel
       	InputAttenuation
	/;
    my $header_str='';
    for my $name (@header_names) {
        $header_str .= "$name = $state{$name}\n";
    }

    return $header_str;
}

sub get_plot_title {
    my ( $self, %args ) = @_;
    my %state = $self->get_loggable_state(%args);

    my @title_names = qw/
	date
       	VBW
       	RBW
       	SweepTime
       	RefLevel
       	InputAttenuation
	/;
    my $title_str;
    my $separator=' ';
    for my $name (@title_names) {
        if ( defined $title_str ) {
            $title_str .= "$separator";
        }
        $title_str .= "$name = $state{$name}";
    }

    return $title_str;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::SpectrumAnalyzer - Role of Generic Spectrum Analyzer for Lab::Moose::Instrument

=head1 VERSION

version 3.682

=head1 DESCRIPTION

Basic commands to make functional basic spectrum analyzer

=head1 NAME

Lab::Moose::Instrument::SpectrumAnalyzer - Role of Generic Spectrum Analyzer

=head1 Hardware capabilities and presets attributes

Not all devices implemented full set of SCPI commands.
With following we can mark what is available

=head2 C<capable_to_query_number_of_X_points_in_hardware>

Can hardware report the number of points in a sweep. I.e. can it respont
to analog of C<[:SENSe]:SWEep:POINts?> command.

Default is 1, i.e true.

=head2 C<capable_to_set_number_of_X_points_in_hardware>

Can hardware set the number of points in a sweep. I.e. can it respont
to analog of C<[:SENSe]:SWEep:POINts> command.

Default is 1, i.e true.

=head2 C<hardwired_number_of_X_points>

Some hardware has fixed/unchangeable number of points in the sweep.
So we can set it here to simplify the logic of some commands.

This is not set by default.
Use C<has_hardwired_number_of_X_points> to check for its availability.

=head1 METHODS

Driver assuming this role must implements the following high-level method:

=head2 C<get_traceXY>

 $data = $sa->traceXY(timeout => 10, trace => 2);

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

=head2 get_StartX and get_StopX 

Returns start and stop frequency

=head2 get_traceY

 $data = $inst->get_traceY(timeout => 1, trace => 2, precision => 'single');

Return Y points of a given trace in a 1D PDL:

This implementation is SCPI friendly.

=over

=item B<timeout>

timeout for the sweep operation. If this is not given, use the connection's
default timeout.

=item B<trace>

number of the trace 1, 2, 3 and so on. Defaults to 1.
It is hardware depended and validated by C<validate_trace_papam>,
which need to be implemented by a specific instrument driver.

=item B<precision>

floating point type. Has to be 'single' or 'double'. Defaults to 'single'.

=back

=head1 Required hardware dependent methods

=head2 validate_trace_param

Validates or applies hardware friendly  aliases to trace parameter.
Need to be implemented by the instrument driver. For example

  sub validate_trace_param {
    my ( $self, $trace ) = @_;
    if ( $trace < 1 || $trace > 3 ) {
      confess "trace has to be in (1..3)";
    }
    return $trace;
  }

Use like this

  $trace = $self->validate_trace_param( $trace );

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2018       Eugeniy E. Mikhailov


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
