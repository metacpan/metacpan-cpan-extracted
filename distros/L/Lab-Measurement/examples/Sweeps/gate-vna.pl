#PODNAME: gate-vna.pl
#ABSTRACT: Gate voltage sweep with VNA spectrum at each point

use 5.010;

use Lab::Moose;

#Sample description
my $sample = 'mysample'; #chip name

#set parameters at devices of the setup
my $gatestart = 0;
my $gateend = 8;
my $stepwidth = 0.02; #stepwidth at gateyoko

my $vna_bw = 10;
my $vna_power = -20;


#instruments

my $vna = instrument(
    type               => 'RS_ZVA',
    connection_type    => 'VXI11',
    connection_options => { host => '192.168.3.27' },
);
# IF bandwidth (Hz)
$vna->sense_bandwidth_resolution( value => $vna_bw );
$vna->sense_sweep_points(value => 1000);
$vna->sense_frequency_start(value => 10e6);
$vna->sense_frequency_stop(value => 150e6);
$vna->source_power_level_immediate_amplitude( value => $vna_power );

my $gateyoko = instrument(
    type => 'YokogawaGS200',
    connection_type => 'LinuxGPIB',
    connection_options => {pad => 2},
    # möglichst kleine Werte
    max_units_per_step => 0.005,
    max_units_per_second => 0.1,
    min_units => -10,
    max_units => 10,
);


#sweep
my $sweep = sweep(
    type       => 'Step::Voltage',
    instrument => $gateyoko,
    delay_in_loop => 0.05,
    from => $gatestart, to => $gateend, step => $stepwidth
);

#datafile
my $datafile = sweep_datafile(columns => [qw/Vg frq Re Im Amp phi/]);
$datafile->add_plot(
type => 'pm3d',
x => 'Vg',
y => 'frq',
z => 'Amp',
);


#measurement
my $meas = sub {
 my $sweep = shift;
 
 my $pdl = $vna->sparam_sweep( timeout => 300 );
 my $Vg = $gateyoko->cached_level();
 
 $sweep->log_block(
        prefix => {Vg => $Vg},
        block => $pdl,
    );
};

#run
$sweep->start(
    measurement => $meas,
    datafile    => $datafile,
    folder => $sample.'_gatevna',
    date_prefix => 1,
    datafile_dim => 2,
    point_dim => 1,
);

__END__

=pod

=encoding UTF-8

=head1 NAME

gate-vna.pl - Gate voltage sweep with VNA spectrum at each point

=head1 VERSION

version 3.904

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by the Lab::Measurement team; in detail:

  Copyright 2022       Andreas K. Huettel, Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
