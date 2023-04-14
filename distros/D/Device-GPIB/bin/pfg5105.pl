#!/usr/bin/perl
#
# pfg5105.pl
#
# Control a Tektronix PFG5105 over GPIB

use strict;
use Device::GPIB::Controller;
use Device::GPIB::Tektronix::PFG5105;

use Getopt::Long;

my @options = 
    (
     'h',                   # Help, show usage
     'port=s',              # port[:baud:databits:parity:stopbits:handshake]
     'address=n',           # GPIB Address of the scope
     'debug',               # Show debugging info like bytes in and out
     'function=s',          # Waveform SINE SQUARE TRIANGLE DC ARBITRARY
     'frequency=s',         # Output frequency
     'amplitude=f',         # Output amplitude in Volts
     'mode=s',              # Mode: CONT TRIG BURST GATE SYNT
     'offset=f',            # Output offset in Volts
     'rate=s',              # Internal trigger interval microseconds, ms, 
     'dc=f',                # DC output voltage
     'nburst=n',            # Number of burst cycles in burst mode
     'dcycle=n',            # Duty cycle percent 10 to 85
     'delay=s',             # Pulse delay
     'width=s',             # Pulse width
     'devicetrigger=s',     # Device trigger mode for GET group trigger TRIG GATE SET OFF
     'trigger=s',           # Trigger source INT EXT MAN
     'sweep=s',             # Sweep shape LIN LOG ARB OFF
     # TODO sweep frequencies
     'am!',                 # Amplitude modulation from AM in
     'fm!',                 # Frequency modulation from VCO/FM in
     'on',                  # Turn output on
     'off',                 # Turn output off
     'arbread=i',           # Read all data from arbitrary data bank 1 or 2. Takes about 15 seconds
     'arbwrite=s@{2,2}',    # Write the data from the named file to the given bank
     'query=s',             # General query and print result to stdout
     'precommands=s',       # List of GPIB and instrument commands to send before anything else
     'postcommands=s',      # List of GPIB and instrument commands to send after anything else
     'errors',              # Print any error
    );

&GetOptions(@options) || &usage;
&usage if $main::opt_h;
my $port = '/dev/ttyUSB0';
my $address = 4;

$port = $main::opt_port if defined $main::opt_port;
$address = $main::opt_address if defined $main::opt_address;
$Device::GPIB::Controller::debug = 1 if $main::opt_debug;

my $d = Device::GPIB::Controller->new($port);

exit unless $d;

my $pfg = Device::GPIB::Tektronix::PFG5105->new($d, $address);
exit unless $pfg;

if (defined $main::opt_precommands)
{
    $pfg->send($main::opt_precommands);
}
if (defined $main::opt_function)
{
    $pfg->setFunction($main::opt_function);
}
if (defined $main::opt_frequency)
{
    $pfg->setFrequency($main::opt_frequency);
}
if (defined $main::opt_amplitude)
{
    $pfg->setAmplitude($main::opt_amplitude);
}
if (defined $main::opt_mode)
{
    $pfg->setMode($main::opt_mode);
}
if (defined $main::opt_offset)
{
    $pfg->setOffset($main::opt_offset);
}
if (defined $main::opt_rate)
{
    $pfg->setRate($main::opt_rate);
}
if (defined $main::opt_nburst)
{
    $pfg->setNburst($main::opt_nburst);
}
if (defined $main::opt_dcycle)
{
    $pfg->setDcycle($main::opt_dcycle);
}
if (defined $main::opt_delay)
{
    $pfg->setDelay($main::opt_delay);
}
if (defined $main::opt_width)
{
    $pfg->setWidth($main::opt_width);
}
if (defined $main::opt_trigger)
{
    $pfg->setTrigger($main::opt_trigger);
}
if (defined $main::opt_devicetrigger)
{
    $pfg->setDeviceTrigger($main::opt_devicetrigger);
}
if (defined $main::opt_sweep)
{
    $pfg->setSweep($main::opt_sweep);
}
if (defined $main::opt_dc)
{
    $pfg->setDC($main::opt_dc);
}
if (defined $main::opt_am)
{
    $pfg->setAM($main::opt_am);
}
if (defined $main::opt_fm)
{
    $pfg->setFM($main::opt_am);
}
if (defined $main::opt_on)
{
    $pfg->setOutput(1);
}
if (defined $main::opt_off)
{
    $pfg->setOutput(0);
}

if (defined $main::opt_query)
{
    print $pfg->sendAndRead($main::opt_query);
    print "\n";
}

if (defined $main::opt_postcommands)
{
    $pfg->send($main::opt_postcommands);
}

if (defined $main::opt_errors)
{
    my @errors = $pfg->getErrorsAsStrings();
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
          [-frequency n.nn[:HZ|KHZ|MHZ]]
          [-function SINE|SQUARE|TRIANGLE|DC|SPULSE|DPULSE]
          [-amplitude n.nn]
          [-mode CONT|TRIG|BURST|GATE|SYNT]
          [-offset n.nn]
          [-rate n.nn[units]]
          [-dc n.nn]
          [-nburst nn]
          [-dcycle nn]
          [-delay n.nn[:NS|US|MS]]
          [-width n.nn[:NS|US|MS]]
          [-devicetrigger TRIG|GATE|SET|OFF]
          [-trigger INT|EXT|MAN]
          [-sweep ON|OFF]
          [-am -no-am]
          [-fm -no-fm]
          [-on]
          [-off]
          [-query gpibquerystring]
          [-precommands gpibcommandstring]
          [-postcommands gpibcommandstring]
          [-errors]\n";
    exit;
}
