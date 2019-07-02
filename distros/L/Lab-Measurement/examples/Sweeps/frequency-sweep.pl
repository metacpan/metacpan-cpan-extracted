#!/usr/bin/env perl
#PODNAME: frequency-sweep.pl
#ABSTRACT: Sweep a R&S SMB rf generator

use 5.010;
use warnings;
use strict;

use Lab::Moose;
use Lab::Measurement;

my $smb = instrument(
    type               => 'RS_SMB',
    connection_type    => 'VXI11',
    connection_options => { host => '192.168.3.26' },
);

my $multimeter = instrument(
    type               => 'HP3458A',
    connection_type    => 'LinuxGPIB',
    connection_options => { gpib_address => 15 },
);

$smb->set_power( value => -10 );    # (dBm)
$multimeter->set_nplc( value => 0.1 );

# No continuous measurement. Start measurement with read request.
$multimeter->set_sample_event( value => 'SYN' );

my $sweep = Sweep(
    'Frequency',
    {
        instrument => $smb,
        mode       => 'step',
        jump       => 1,
        points     => [ 1e6, 2e6 ],
        stepwidth  => [1000],
        rate       => [0.1],          # ignored with Lab::Moose instrument
    }
);

my $DataFile = DataFile('Data');
$DataFile->add_column('frq');
$DataFile->add_column('volt');

my $measurement = sub {
    my $sweep = shift;
    my $frq   = $smb->cached_frq();
    my $volt  = $multimeter->get_value();
    say "frq: $frq, volt: $volt";
    $sweep->LOG( { frq => $frq, volt => $volt } );
};

$DataFile->add_measurement($measurement);
$sweep->add_DataFile($DataFile);
$sweep->start();

__END__

=pod

=encoding UTF-8

=head1 NAME

frequency-sweep.pl - Sweep a R&S SMB rf generator

=head1 VERSION

version 3.682

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2017       Simon Reinhardt
            2018       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
