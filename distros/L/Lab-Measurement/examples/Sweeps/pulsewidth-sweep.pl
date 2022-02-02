#PODNAME: pulsewidth-sweep.pl
#ABSTRACT: Sweep the pulsewidth with a Rigol DG5352 and measure with the Keysight DSOS604A Oscilloscope

use Lab::Moose;

# Initialize the Rigol with PULSE as the output function
my $source = instrument(
    type            => 'Rigol_DG5000',
    connection_type => 'USB',
    connection_options => {host => '192.168.3.34'},
    function => 'PULSE'
);

# Initialize the Oscilloscope with float as the acquisition format and 1MOhm
# input impedance on channel 1
my $osc = instrument(
  type => 'KeysightDSOS604A',
  connection_type => 'VXI11',
  connection_options => {host => '192.168.3.33'},
  waveform_format => 'FLOat',
  input_impedance => 'DC',
  instrument_nselect => 1
);

# Define the sweep as a Pulsewidth Sweep with from, to and step parameters as
# always, additionally the constant_delay is set to true.
my $sweep = sweep(
  type       => 'Step::Pulsewidth',
  instrument => $source,
  from => 0.0000000025, to => 0.000000100, step => 0.0000000025,
  constant_delay => 1
);

# Provide a constant amplitude, delay and number of acquired periods
my $amp = 1;
my $delay = 0.000000250;
my $cycles = 2;

# Input the parameters to the Rigol...
$source->set_level(value => $amp);
$source->set_period(value => $delay+$sweep->from);
$source->set_pulsedelay(value => $delay);
# ...and to the Oscilloscope
$osc->channel_offset(offset => 0.5);
$osc->channel_range(range => 1.5);
$osc->trigger_level(value => 0.5);
$osc->timebase_range(value => $cycles*($sweep->to+$delay));

# Define a datafile to save the results
my $datafile = sweep_datafile(columns => [qw/pulsewidth time voltage/]);

# Define the actual measurement routine
my $meas = sub {
    my $sweep = shift;
    # Download the waveform. get_waveform() returns the time and voltage axis
    my $waveform = $osc->get_waveform();
    # Log it into the sweep
    $sweep->log_block(
        prefix => {pulsewidth => $source->get_pulsewidth()},
        block => $waveform
    );
};

# Finally execute the measurement. With these settings every pulsewidth gets its
# own data file
$sweep->start(
    measurement => $meas,
    datafile    => $datafile,
    datafile_dim => 1,
    point_dim => 1,
    # Include the sweep parameters in the folder name
    folder => $sweep->from."s_to_".$sweep->to."s_step_".$sweep->step."s_delay_".$delay."s"
);

__END__

=pod

=encoding UTF-8

=head1 NAME

pulsewidth-sweep.pl - Sweep the pulsewidth with a Rigol DG5352 and measure with the Keysight DSOS604A Oscilloscope

=head1 VERSION

version 3.803

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by the Lab::Measurement team; in detail:

  Copyright 2021       Fabian Weinelt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
