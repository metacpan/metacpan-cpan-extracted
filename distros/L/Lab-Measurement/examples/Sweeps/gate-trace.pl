#!/usr/bin/perl
#PODNAME: gate-trace.pl
#ABSTRACT: Measure a gate trace

use Lab::Moose;
use 5.010;

# Sample

my $sample = 'mysample_';  # chip name
my $PINsI = 'Vsd#2#3_';    # pins / cables
my $PINGate = 'Vg#6_';     # pins / cables

# parameters of the setup

my $lineresistance=4000; # resistance of measurement line (Ohm)
my $sensitivity = -1e-9; # sensitivity of DL1211 in A/V
my $risetime = 30;       # rise time in ms

my $biasvoltage = 0.2;   # voltage set to biasyokogawa
my $divider = 1000;      # voltage divider

my $samplebias = ($biasvoltage/$divider);

# parameters of the gate trace

my $gatestart = -2;
my $gateend = 5;
my $stepwidth = 0.001;

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
    max_units_per_step => 0.002,
    max_units_per_second => 0.1,
    min_units => -10,
    max_units => 10,
);

# sweep

my $sweep = sweep(
    type       => 'Step::Voltage',
    instrument => $gateyoko,
    delay_in_loop => 0.05,
    from => $gatestart, to => $gateend, step => $stepwidth
);

# data file

my $datafile = sweep_datafile(columns => [qw/voltage current/]);
$datafile->add_plot(
x => 'voltage',
y => 'current',);

# measurement

my $meas = sub {
  my $sweep = shift;
 
  my $current = $multimeter->get_value();
  my $i_dc = $current*($sensitivity); 
 
  $sweep->log(
        voltage => $gateyoko->cached_level(),
        current => $i_dc,
  );
};

# run it

$biasyoko->set_level(value => $biasvoltage);
$sweep->start(
    measurement => $meas,
    datafile    => $datafile,
    folder => 'gatetrace',
    date_prefix => 1,
);

__END__

=pod

=encoding UTF-8

=head1 NAME

gate-trace.pl - Measure a gate trace

=head1 VERSION

version 3.682

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2018       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
