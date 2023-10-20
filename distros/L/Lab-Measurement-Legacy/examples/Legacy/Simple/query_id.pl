#!/usr/bin/perl

use strict;
use Lab::Instrument;

################################

unless ( @ARGV > 0 ) {
    print "Usage: $0 GPIB-address\n";
    exit;
}

my $gpib = $ARGV[0];

print "Querying ID of instrument at GPIB address $gpib\n";

my $i = new Lab::Instrument(
    connection_type => 'LinuxGPIB',
    gpib_address    => $gpib,
    gpib_board      => 0,
);

my $id = $i->query('*IDN?');

print "Query result: \"$id\"\n";

1;

=pod

=encoding utf-8

=head1 query_id.pl

Queries and prints the instrumet ID of a GPIB instrument; the GPIB address is the only
command line parameter.

=head2 Usage example

  $ perl query_id.pl 3
  
=head2 Author / Copyright

  (c) Andreas K. Hüttel 2011

=cut
