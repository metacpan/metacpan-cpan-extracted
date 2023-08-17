#!/usr/bin/perl
#
# hp5342a.pl
#
# Control a HP5342A over GPIB
#
# Some sample commands:
# perl -I lib bin/hp5342a.pl -waitdataready 
# perl -I lib bin/hp5342a.pl -waitdataready -loop 2 -timestamp -precommands 'SR9'
#
### CAUTION:
# On some HP5342A, the GPIB board is not configured to enable SRQ. The W1 link is missing and must be soldered in.
# Its not even marked on the board and has to be found by belling out. It is near pin 13A on the edge connector.
###

use strict;
use Device::GPIB::Controller;
use Device::GPIB::HP::HP5342A;
use Getopt::Long;

my @options = 
    (
     'h',                   # Help, show usage
     'port=s',              # port[:baud:databits:parity:stopbits:handshake]
     'address=n',           # GPIB Address of the scope
     'debug',               # Show debugging info like bytes in and out
     'delay=n',             # Delay n seconds between reads
     'timestamp',           # Print timestamp at beginning of each line
     'loop=n',              # Loop this number of times. 0 means forever
     'waitdataready',       # Wait until a Data Ready SRQ occurs before reading
     'query=s',             # General query and print result to stdout
     'precommands=s',       # List of GPIB and instrument commands to send before anything else
     'postcommands=s',      # List of GPIB and instrument commands to send after anything else
    );

&GetOptions(@options) || &usage;
&usage if $main::opt_h;
my $port = '/dev/ttyUSB0';
my $address = 6;

$port = $main::opt_port if defined $main::opt_port;
$address = $main::opt_address if defined $main::opt_address;
$Device::GPIB::Controller::debug = 1 if $main::opt_debug;

my $d = Device::GPIB::Controller->new($port);

exit unless $d;

my $counter = Device::GPIB::HP::HP5342A->new($d, $address);
exit unless $counter;

my $loop_count = 0;

#$d->clr();
$counter->read(); # Get into remote mode

if (defined $main::opt_precommands)
{
    $counter->send($main::opt_precommands);
}

do
{
    if (defined $main::opt_waitdataready)
    {
	$counter->send('ST2'); # Stop after measurement until read, assert SRQ
	$d->trg();
	$counter->waitSRQ();
    }

    # Expect to read data something like:
    #  F  00010.000000E+06
    #  F  00010.000000E+06, A +10.0E+0
    #  FS+00001.000000E+06
    #  FS+00001.000000E+06, AS+10.0E+0
    my $value = $counter->read();
    print scalar localtime() . ': '
	if $main::opt_timestamp;
    print "$value\n";
    
    sleep($main::opt_delay)
	if $main::opt_delay;
}
while (defined $main::opt_loop && ($main::opt_loop == 0 || (++$loop_count < $main::opt_loop)));

if (defined $main::opt_query)
{
    print $counter->sendAndRead($main::opt_query);
    print "\n";
}

if (defined $main::opt_postcommands)
{
    $counter->send($main::opt_postcommands);
}

sub usage
{
    print "usage: $0 [-h]
          [-port [Prologix:[port[:baud:databits:parity:stopbits:handshake]]] 
          [-port LinuxGpib:[board_index]]
    	  [-address n]
	  [-loop count]
 	  [-waitdataready]
          [-delay n] 
          [-timestamp]
          [-query gpibquerystring]
          [-precommands gpibcommandstring]
          [-postcommands gpibcommandstring]\n";
    exit;
}

