#!/usr/bin/perl
#
# dm5010.pl
#
# Gets DC voltage values (or other values, see -measure) from a Tek DM5010
# Prints on stdout
# Caution: for fast response to reads, expects the DM5010 to be configured for LF not EOI
# Reads as fast as it can unless a -delay is specified.

use strict;
use Device::GPIB::Controller;
use Device::GPIB::Tektronix::DM5010;

use Getopt::Long;

my @options = 
    (
     'h',                   # Help, show usage
     'port=s',              # port[:baud:databits:parity:stopbits:handshake]
     'address=n',           # GPIB Address of the scope
     'debug',               # Show debugging info like bytes in and out
     'delay=n',             # Delay n seconds between reads
     'timestamp',           # Print timestamp at beginning of each line
     'function=s',          # Unit to measure. Defaults to DCV. Can be ACA,ACV,DBM,DBV,DCA,DCV,OHM,TEMP
     'loop=n',              # Loop this number of times. 0 means forever
     'query=s',             # General query and print result to stdout
     'precommands=s',       # List of GPIB and instrument commands to send before anything else
     'postcommands=s',      # List of GPIB and instrument commands to send after anything else
     'errors',              # Print any error
    );

&GetOptions(@options) || &usage;
&usage if $main::opt_h;
my $port = '/dev/ttyUSB0';
my $address = 14;
my $function = 'DCV';

$port = $main::opt_port if defined $main::opt_port;
$address = $main::opt_address if defined $main::opt_address;
$Device::GPIB::Controller::debug = 1 if $main::opt_debug;
$function =  uc($main::opt_function) if defined $main::opt_function;

my $d = Device::GPIB::Controller->new($port);

exit unless $d;

my $meter = Device::GPIB::Tektronix::DM5010->new($d, $address);
exit unless $meter;

# $meter->init();
# $meter->setFunction('TEMP');
#my $function = $meter->getFunction();
#print "function $function\n";
# my $err = $meter->getError();
# print "err $err\n";
# $meter->setSource('rear');
# my $source = $meter->getSource();
# print "source $source\n";
#my $test = $meter->test();
#print "test result $test\n";
#exit;

my $loop_count = 0;

if (defined $main::opt_precommands)
{
    $meter->send($main::opt_precommands);
}
do
{
    my $value = $meter->measure($function);
    print scalar localtime() . ': '
	if $main::opt_timestamp;
    print "$value\n";

    sleep($main::opt_delay)
	if $main::opt_delay;
}
while (defined $main::opt_loop && ($main::opt_loop == 0 || (++$loop_count < $main::opt_loop)));


if (defined $main::opt_query)
{
    print $meter->sendAndRead($main::opt_query);
    print "\n";
}

if (defined $main::opt_postcommands)
{
    $meter->send($main::opt_postcommands);
}

if (defined $main::opt_errors)
{
    my @errors = $meter->getErrorsAsStrings();
    foreach my $error (@errors)
    {
	print "$error\n";
    }
}

sub usage
{
    print "usage: $0 [-h]
          [-address n]
          [-port [Prologix:[port[:baud:databits:parity:stopbits:handshake]]] 
          [-port LinuxGpib:[board_index]]
          [-delay n] 
          [-timestamp]
          [-function ACV|DCV|ACDC|DIODE|OHMS [units]]
          [-query gpibquerystring]
          [-precommands gpibcommandstring]
          [-postcommands gpibcommandstring]
          [-loop n]
          [-errors]\n";
    exit;
}



