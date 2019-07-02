#!/usr/bin/env perl
#PODNAME: voltage-sweep.pl
#ABSTRACT: Sweep a Yokogawa GS200 voltage source

use 5.010;
use warnings;
use strict;

use Lab::Moose;
use Lab::Measurement;

my $yoko = instrument(
    type               => 'YokogawaGS200',
    connection_type    => 'LinuxGPIB',
    connection_options => { gpib_address => 1 },

    # Mandatory protection settings.
    # Important, as instrument will always do step-sweeps.
    max_units_per_step   => 0.01,
    max_units_per_second => 10000,
    max_units            => 10,
    min_units            => -10,
);

my $multimeter = instrument(
    type               => 'HP3458A',
    connection_type    => 'LinuxGPIB',
    connection_options => { gpib_address => 15 },
);
$multimeter->set_nplc( value => 1 );

# No continuous measurement. Start measurement with read request.
$multimeter->set_sample_event( value => 'SYN' );

my $sweep = Sweep(
    'Voltage',
    {
        instrument => $yoko,
        mode       => 'step',
        jump       => 1,
        points     => [ 0, 0.3 ],
        stepwidth  => [0.001],

        # The rate parameter is ignored by Lab::Moose Instruments,
        # Use max_units_per_step and max_units_per_second
        rate => [0.1],
    }
);

my $DataFile = DataFile('Data');
$DataFile->add_column('gate');
$DataFile->add_column('volt');

my $measurement = sub {
    my $sweep = shift;
    my $gate  = $yoko->cached_level();
    my $volt  = $multimeter->get_value();
    say "gate: $gate, volt: $volt";
    $sweep->LOG( { gate => $gate, volt => $volt } );
};

$DataFile->add_measurement($measurement);
$sweep->add_DataFile($DataFile);
$sweep->start();

__END__

=pod

=encoding UTF-8

=head1 NAME

voltage-sweep.pl - Sweep a Yokogawa GS200 voltage source

=head1 VERSION

version 3.682

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2017       Simon Reinhardt
            2018       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
