#!/usr/bin/perl
#
# gpib.pl
#
# Control any GPIB device

use strict;
use Device::GPIB::Controller;
use Device::GPIB::Generic;

use Getopt::Long;

my @options = 
    (
     'h',                   # Help, show usage
     'port=s',              # port[:baud:databits:parity:stopbits:handshake]
     'address=n',           # GPIB Address of the device
     'debug',               # Show debugging info like bytes in and out
     'spoll',               # Spoll the device and print the results
     'trigger',             # Send a GET trigger to this device
     'file=s@'              # File(s) to read commands from
    );

&GetOptions(@options) || &usage;
&usage if $main::opt_h;
my $port = '/dev/ttyUSB0';
my $address = 7;

$port = $main::opt_port if defined $main::opt_port;
$address = $main::opt_address if defined $main::opt_address;
$Device::GPIB::Controller::debug = 1 if $main::opt_debug;

my $d = Device::GPIB::Controller->new($port);
exit unless $d;

my $gpib = Device::GPIB::Generic->new($d, $address);
exit unless $gpib;

$d->clr();

$gpib->executeCommandsFromFiles(@main::opt_file);
$gpib->executeCommands(@ARGV);

if (defined $main::opt_trigger)
{
    $gpib->trigger();
}


if (defined $main::opt_spoll)
{
    my @spoll = $gpib->spoll();
    if (@spoll)
    {
	print @spoll;
	print "\n";
    }
}

sub usage
{
    print "usage: $0 [-h]
    	  [-address n]
          [-port [Prologix:[port[:baud:databits:parity:stopbits:handshake]]] 
          [-port LinuxGpib:[board_index]]
          [-spoll]                                   Read all queued SRQs from the device with SPOLL
          [-trigger]                                 Send a GET trigger to the device
          [-file filename [-file filename]]          Send commands from file. Results of queries are printed
          \"commandstring;commandstring;...\"        Sends the commands to the device. 
	  \"commandstring;querystring?\"             Sends the optional commands and the query, prints the result of the query
\n";
    exit;
}
