#!/usr/bin/perl

use strict;
use Lab::Instrument;
use Lab::Connection::VISA_RS232;

################################

unless ( @ARGV > 0 ) {
    print "Usage: $0 isobus-address\n";
    print
"You will have to modify this script to use the correct base connection for your setup.\n";
    exit;
}

my $iba = $ARGV[0];

print "Querying ID of instrument at IsoBus address $iba\n";

my $i = new Lab::Instrument(
    connection_type => 'IsoBus',
    isobus_addres   => $iba,
    base_connection => new Lab::Conection::VISA_RS232(
        {
            rs232_address => 1,
            baud_rate     => 9600,
        }
    ),
);

my $id = $i->query('*IDN?');

print "Query result: \"$id\"\n";

1;

=pod

=encoding utf-8

=head1 query_id.pl

Queries and prints the instrumet ID of an IsoBus instrument; the IsoBus address is the only
command line parameter.

You will have to adapt this script first to use the correct IsoBus base connection. This base
connection describes how the IsoBus is connected to your measurement PC. 

For example, the IsoBus could be connected to a bus master device (often an IPS magnet power supply), 
and that in turn has a GPIB address. Then, the base connection would be the GPIB connection to the 
bus master device. 

Alternatively, as shown above, the IsoBus is connected directly to the PC, and the base connection
is then just the serial port.

=head2 Usage example

  $ perl isobus_query_id.pl 3
  
=head2 Author / Copyright

  (c) Andreas K. Hüttel 2011,2013

=cut
