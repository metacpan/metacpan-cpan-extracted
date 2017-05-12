#!/usr/bin/perl

use strict;
use Lab::Instrument::Yokogawa7651;

unless ( @ARGV > 0 ) {
    print "Usage: $0 GPIB-address [Target-voltage]\n";
    exit;
}

my ( $gpib, $goto ) = @ARGV;

my $source = new Lab::Instrument::Yokogawa7651(
    connection_type         => 'VISA_GPIB',
    gpib_address            => $gpib,
    gpib_board              => 0,
    gate_protect            => 1,
    gp_max_units_per_second => 0.05,
    gp_max_step_per_second  => 10,
    gp_max_units_per_step   => 0.005
);

if ( defined $goto ) {
    $source->set_voltage($goto);
}
else {
    print $source->get_voltage();
}

1;

=pod

=encoding utf-8

=head1 yoko-goto.pl

Sweeps a Yokogawa 7651 dc voltage source to a value given on the command line. 

=head2 Usage example

  $ perl yoko_goto.pl 12 0.8

Sweeeps the Yokogawa 7651 dc voltage source with GPIB address 12 (on GPIB adaptor 0) to 0.8V, 
using a maximum step size of 5mV and at most 10 steps per second.

=head2 Author / Copyright

  (c) Andreas K. Hüttel 2011

=cut
