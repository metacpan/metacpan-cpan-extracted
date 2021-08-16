# PODNAME: singlechannel_sweep.pl
# ABSTRACT: Use Rigol_DG5000 with KeysightDSOS604A

use Lab::Moose;
use Lab::Moose::Instrument::Rigol_DG5000;
use Lab::Moose::Instrument::KeysightDSOS604A;

my $source = instrument(
    type            => 'Rigol_DG5000',
    connection_type => 'USB',
    connection_options => {host => '192.168.3.34'},
);

my $osc = instrument(
  type => 'KeysightDSOS604A',
  connection_type => 'VXI11',
  connection_options => {host => '192.168.3.33'},
);

my $delay = 0.000000300;
my $amp = 1;
my $scal = 2;
my $cycles = 1;

my $before_loop = sub {
  $source->output_toggle(channel => 1, value => 'OFF');
  $source->output_toggle(channel => 2, value => 'OFF');
  $source->source_function_shape(channel => 1, value => 'PULSE');
  $source->source_apply_pulse(channel => 1, freq => 1/$delay, amp => $amp, offset => $amp/2, delay => $delay);
  $source->output_toggle(channel => 1, value => 'ON');

  $osc->write(command => ":DIGitize CHANnel1");
  $osc->write(command => ":CHANnel1:DISPlay ON");
  $osc->write(command => ":WAVeform:FORMat FLOat" ); # Setup transfer format
  $osc->write(command => ":WAVeform:BYTeorder LSBFirst" ); # Setup transfer of LSB first
  $osc->write(command => ":WAVeform:SOURce CHANnel1" ); # Waveform data ata source channel 1
  $osc->write(command => ":WAVeform:STReaming ON" ); # Turn on waveform streaming of data
  $osc->timebase_reference(value => 'LEFT');
  $osc->timebase_ref_perc(value => 5);
  $osc->channel_input(channel => 'CHANnel1', parameter => 'DC50');
  # $osc->acquire_points(value => 10000);
  $osc->write(command => ":TRIGger:EDGE:SOURce CHANnel1");
  $osc->write(command => ":TRIGger:EDGE:SLOPe POSitive");
};

my $sweep = sweep(
    type       => 'Step::Pulsewidth',
    instrument => $source,
    from => 0.000000005, to => 0.000000100, step => 0.000000005,
    before_loop => $before_loop,
);

my $datafile = sweep_datafile(columns => [qw/pulsewidth time voltage/]);

$datafile->add_plot(
   x => 'time',
   y => 'voltage',
);

my $meas = sub {
    my $sweep = shift;
    $osc->write(command => ':SINGle');
    $osc->channel_offset(channel => 'CHANnel1', offset => $amp/(2*$scal));
    $osc->channel_range(channel => 'CHANnel1', range => 1.5*$amp/$scal);
    $osc->trigger_level(channel => 'CHANnel1', level => $amp/(2*$scal));
    my $pulsewidth = $source->get_pulsewidth();
    $osc->timebase_range(value => $cycles*($pulsewidth+$delay));
    my $voltages = $osc->get_waveform_voltage();
    my $xOrg = $osc->query(command => ":WAVeform:XORigin?");
    my $xInc = $osc->query(command => ":WAVeform:XINCrement?");
    my @time;
    foreach (1..@$voltages) {@time[$_-1] = $_*$xInc+$xOrg}
    $sweep->log_block(
        prefix => {pulsewidth => $pulsewidth},
        block => [\@time, $voltages]
    );
};

$sweep->start(
    measurement => $meas,
    datafile    => $datafile,
    datafile_dim => 1,
    point_dim => 1,
);

__END__

=pod

=encoding UTF-8

=head1 NAME

singlechannel_sweep.pl - Use Rigol_DG5000 with KeysightDSOS604A

=head1 VERSION

version 3.770

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by the Lab::Measurement team; in detail:

  Copyright 2021       Andreas K. Huettel, Fabian Weinelt, Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
