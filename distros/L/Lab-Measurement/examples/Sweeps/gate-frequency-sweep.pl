#!/usr/bin/perl
#PODNAME: gate-frequency-sweep.pl
#ABSTRACT: Sweep a gate voltage and a rf generator frequency
use 5.010;
use Lab::Moose;

# Sample description
my $sample = 'mysample_'; # chip name
my $PINsI = 'Vbias#2#3_'; # bias pins
my $PINGate = 'Gate#6_';  # gate pin

# parameters of the setup

my $lineresistance=4000; #resistance of measurement line (Ohm)
my $sensitivity = -1e-9; #sensitivity of DL1211 in A/V
my $risetime = 30; #risetime in ms

my $biasvoltage = 0.2; # voltage set to biasyokogawa
my $divider = 1000;    # bias voltage divider
my $samplebias = ($biasvoltage/$divider);

my $gatestart = -6;
my $gateend = 6;
my $gatestepwidth = 0.02;

my $freqstart = 10e6;
my $freqend = 250e6;
my $freqstepwidth = 100e3;
my $power = -10;

# instruments

my $multimeter = instrument(
    type => 'Keysight34470A',
    connection_type => 'VXI11',
    connection_options => {host => '192.168.3.28'},
);
$multimeter->sense_nplc(value => '1');

my $biasyoko = instrument(
    type => 'YokogawaGS200',
    connection_type => 'LinuxGPIB',
    connection_options => {pad => 2},
    max_units_per_step => 0.05,
    max_units_per_second => 1,
    min_units => -5,
    max_units => 5,
);

my $gateyoko = instrument(
    type => 'YokogawaGS200',
    connection_type => 'LinuxGPIB',
    connection_options => {pad => 1},
    max_units_per_step => 0.01,
    max_units_per_second => 0.1,
    min_units => -10,
    max_units => 10,
);

my $smb = instrument(
   type => 'RS_SMB',
   connection_type => 'VXI11',
   connection_options => {host => '192.168.3.26'},
   );
$smb->set_power(value => $power);

# sweep

my $sweep_gate = sweep(
    type       => 'Step::Voltage',
    instrument => $gateyoko,
    from => $gatestart, to => $gateend, step => $gatestepwidth
);

my $sweep_freq = sweep(
    type       => 'Step::Frequency',
    instrument => $smb,
    delay_in_loop => 0.05,
    from => $freqstart, to => $freqend, step => $freqstepwidth
);

#data file

my $datafile = sweep_datafile(columns => [qw/gate frequency current/]);
$datafile->add_plot(
type => 'pm3d',
x => 'gate',
y => 'frequency',
z => 'current',);

# measurement

my $meas = sub {
 my $sweep = shift;
 
 my $current = $multimeter->get_value();
 my $i_dc = $current*($sensitivity); 
 
    $sweep->log(
        gate => $gateyoko->cached_level(),
        frequency => $smb->cached_frq(),
        current => $i_dc,
    );
};

# run

$biasyoko->set_level(value => $biasvoltage);
$smb->output_state(value => 'ON');
$sweep_gate->start(
    slave => $sweep_freq,
    measurement => $meas,
    datafile    => $datafile,
    folder => 'gatefreq',
    date_prefix => 1,
);
$smb->output_state(value => 'OFF');

__END__

=pod

=encoding UTF-8

=head1 NAME

gate-frequency-sweep.pl - Sweep a gate voltage and a rf generator frequency

=head1 VERSION

version 3.682

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2018       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
