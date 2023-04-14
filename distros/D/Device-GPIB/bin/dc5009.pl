#!/usr/bin/perl
#
# dc5009.pl
#
# Control a Tektronix DC5009 over GPIB

use strict;
use Device::GPIB::Controller;
use Device::GPIB::Tektronix::DC5009;

use Getopt::Long;

my @options = 
    (
     'h',                   # Help, show usage
     'port=s',              # port[:baud:databits:parity:stopbits:handshake]
     'address=n',           # GPIB Address of the scope
     'debug',               # Show debugging info like bytes in and out
     'frequency',           # Read frequency from channel A
     'period',              # Read frequencyeriod from channel A
     'ratio',               # Read ratio of events in channel B on events in channel A
     'time',                # Read time interval from first event on A to succeeding event on B
     'width',               # Read pulse width on channel A
     'totalize',            # Read total events on channel A
     'start',               # Start reading
     'stop',                # Start reading
     'read',                # REad and sisplay the current value
     'query=s',             # General query and print result to stdout
     'precommands=s',       # List of GPIB and instrument commands to send before anything else
     'postcommands=s',      # List of GPIB and instrument commands to send after anything else
     'errors',              # Print any error
     'loop=n',              # Loop this number of times. 0 means forever
    );

&GetOptions(@options) || &usage;
&usage if $main::opt_h;
my $port = '/dev/ttyUSB0';
my $address = 18; # Factory default

$port = $main::opt_port if defined $main::opt_port;
$address = $main::opt_address if defined $main::opt_address;
$Device::GPIB::Controller::debug = 1 if $main::opt_debug;

my $d = Device::GPIB::Controller->new($port);
exit unless $d;

my $counter = Device::GPIB::Tektronix::DC5009->new($d, $address);
exit unless $counter;

# You can use the TMANUALmode like this to measure time intervals
#$counter->tmanual();
#$counter->start();
#sleep 3;
#$counter->stop();
#my $x = $counter->readResult();
#print "time $x\n";

my $loop_count = 0;

do
{
    if (defined $main::opt_precommands)
    {
	$counter->send($main::opt_precommands);
    }
    if (defined $main::opt_frequency)
    {
	my $value = $counter->frequency();
	print "$value\n";
    }
    if (defined $main::opt_period)
    {
	my $value = $counter->period();
	print "$value\n";
    }
    if (defined $main::opt_ratio)
    {
	my $value = $counter->ratio();
	print "$value\n";
    }
    if (defined $main::opt_time)
    {
	my $value = $counter->time();
	print "$value\n";
    }
    if (defined $main::opt_width)
    {
	my $value = $counter->width();
	print "$value\n";
    }
    if (defined $main::opt_totalize)
    {
	$counter->totalize();
    }
    if (defined $main::opt_start)
    {
	$counter->start();
    }
    if (defined $main::opt_stop)
    {
	$counter->stop();
    }
    if (defined $main::opt_read)
    {
	my $value = $counter->readResult();
	print "$value\n";
    }
    if (defined $main::opt_query)
    {
	print $counter->sendAndRead($main::opt_query);
	print "\n";
    }
    if (defined $main::opt_postcommands)
    {
	$counter->send($main::opt_postcommands);
    }

}
while (defined $main::opt_loop && ($main::opt_loop < 0 || ++$loop_count < $main::opt_loop));

if (defined $main::opt_errors)
{
    my @errors = $counter->getErrorsAsStrings();
    foreach my $error (@errors)
    {
	print "$error\n";
    }
}


sub usage
{
    print "usage: $0 [-h] [-port port[:baud:databits:parity:stopbits:handshake]] 
           [-port [Prologix:[port[:baud:databits:parity:stopbits:handshake]]] 
           [-port LinuxGpib:[board_index]]
     	   [-address n] [-debug]
           [-frequency]
           [-period]
           [-ratio]
           [-time]
           [-width]
           [-totalize]
           [-start]
           [-stop]
           [-read]
           [-query gpibquerystring]
           [-precommands gpibcommandstring]
           [-postcommands gpibcommandsstring]
           [loop n]
          [-errors]\n";
    exit;
}
