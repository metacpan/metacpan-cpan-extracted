#!/usr/bin/perl
#
# hp3456a.pl
#
# Control a HP3456A over GPIB
#
# Some sample commands:
# Continuously read temperature in C from 2 wire thermistor (math function) with timestamps:
# hp3456a.pl -function '2WOHMS' -precommands "M6" -timestamp -loop -1

use strict;
use Device::GPIB::Controller;
use Device::GPIB::HP::HP3456A;

use Getopt::Long;

my @options = 
    (
     'h',                   # Help, show usage
     'port=s',              # port[:baud:databits:parity:stopbits:handshake]
     'address=n',           # GPIB Address of the scope
     'debug',               # Show debugging info like bytes in and out
     'delay=n',             # Delay n seconds between reads
     'timestamp',           # Print timestamp at beginning of each line
     'function=s',          # Unit to measure. Defaults to DCV.
     'range=s',             # Measurement range.
     'trigger=s',           # Trigger type
     'digits=i',            # Digits to display
     'powerlinecycles=n',   # Powerline cycles
     'loop=n',              # Loop this number of times. 0 means forever
     'waitdataready',       # Wait until a Data Ready SRQ occurs before reading
     'query=s',             # General query and print result to stdout
     'precommands=s',       # List of GPIB and instrument commands to send before anything else
     'postcommands=s',      # List of GPIB and instrument commands to send after anything else
    );

&GetOptions(@options) || &usage;
&usage if $main::opt_h;
my $port = '/dev/ttyUSB0';
my $address = 22;
my $function = 'DCV';

$port = $main::opt_port if defined $main::opt_port;
$address = $main::opt_address if defined $main::opt_address;
$Device::GPIB::Controller::debug = 1 if $main::opt_debug;
$function =  uc($main::opt_function) if defined $main::opt_function;

my $d = Device::GPIB::Controller->new($port);

exit unless $d;

my $meter = Device::GPIB::HP::HP3456A->new($d, $address);
exit unless $meter;

# Testing:
#$meter->setTrigger('INTERNAL');
#$meter->setAutozero(1);
#$meter->setDigitsDisplayed(5);

#$meter->send('HSM002L1RS110STNT3QX1');
#$meter->waitFrontPanelSRQ();

my $loop_count = 0;

if (defined $main::opt_precommands)
{
    $meter->send($main::opt_precommands);
}

if (defined $main::opt_range)
{
    $meter->setRange($main::opt_range);
}

if (defined $main::opt_digits)
{
    $meter->setDigitsDisplayed($main::opt_digits);
}

if (defined $main::opt_powerlinecycles)
{
    $meter->setPowerlineCycles($main::opt_powerlinecycles);
}

if (defined $main::opt_trigger)
{
    $meter->setTrigger($main::opt_trigger);
}

do
{
    if (defined $main::opt_waitdataready)
    {
	# User can trigger SINGLE measurement, provided HP is in LOCAL mode
	# or perhaps EXTERNAL
	$meter->setFunction($function);
	$meter->waitDataReadySRQ();
    }

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

sub usage
{
    print "usage: $0 [-h]
          [-port [Prologix:[port[:baud:databits:parity:stopbits:handshake]]] 
          [-port LinuxGpib:[board_index]]
    	  [-address n]
          [-delay n] 
          [-timestamp]
          [-function DCV|ACV|ACV+DCV|2WOHMS|DCV/ACV|ACV/DCV|ACV+DCV/DCV|OC2WOHMS| OC4WOHMS]
          [-range AUTO|100mV|1000mV|1V|10V|100V|1000V|100Ohms|1KOhms|1KOhms|10KOhms|1MOhms|10MOhms|100MOhms|1000MOhms]
          [-trigger INTERNAL|EXTERNAL|SINGLE|HOLD]
          [-digits 3|4|5|6]
          [-powerlinecycles 1|10|100]
          [-query gpibquerystring]
          [-precommands gpibcommandstring]
          [-postcommands gpibcommandstring]\n";
    exit;
}

