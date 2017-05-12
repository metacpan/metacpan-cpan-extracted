#!/usr/bin/perl

use strict;
use Lab::Instrument::SR830;

################################

unless ( @ARGV > 0 ) {
    print "Usage: $0 GPIB-address\n";
    exit;
}

my $gpib = $ARGV[0];

print "Reading status and signal r/phi from SR830 at GPIB address $gpib\n";

my $sr = new Lab::Instrument::SR830(
    connection_type => 'LinuxGPIB',
    gpib_address    => $gpib,
    gpib_board      => 0,
);

my $amp = $sr->get_amplitude();
print "Reference amplitude: $amp V\n";

my $freq = $sr->get_frequency();
print "Reference frequency: $freq Hz\n";

my ( $r, $phi ) = $sr->get_rphi();
print "Signal             : r=$r V   phi=$phi\n";

1;

=pod

=encoding utf-8

=head1 srs_read.pl

Reads out reference amplitude, reference frequency, and current r and phi values
of a Stanford Research SR830 lock-in amplifier. The only command line parameter is the
GPIB address.

=head2 Usage example

  $ perl srs_read.pl 8

=head2 Author / Copyright

  (c) Andreas K. Hüttel 2011

=cut
