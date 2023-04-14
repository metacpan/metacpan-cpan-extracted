#!/usr/bin/perl
#
# afg5101.pl
#
# Control a Tektronix AFG5101 over GPIB

use strict;
use Device::GPIB::Controller;
use Device::GPIB::Tektronix::AFG5101;

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
my $address = 7;

$port = $main::opt_port if defined $main::opt_port;
$address = $main::opt_address if defined $main::opt_address;
$Device::GPIB::Controller::debug = 1 if $main::opt_debug;

my $d = Device::GPIB::Controller->new($port);

exit unless $d;

my $afg = Device::GPIB::Tektronix::AFG5101->new($d, $address);
exit unless $afg;

if (defined $main::opt_precommands)
{
    $afg->send($main::opt_precommands);
}
if (defined $main::opt_function)
{
    $afg->setFunction($main::opt_function);
}
if (defined $main::opt_frequency)
{
    $afg->setFrequency($main::opt_frequency);
}
if (defined $main::opt_amplitude)
{
    $afg->setAmplitude($main::opt_amplitude);
}
if (defined $main::opt_mode)
{
    $afg->setMode($main::opt_mode);
}
if (defined $main::opt_offset)
{
    $afg->setOffset($main::opt_offset);
}
if (defined $main::opt_rate)
{
    $afg->setRate($main::opt_rate);
}
if (defined $main::opt_nburst)
{
    $afg->setNburst($main::opt_nburst);
}
if (defined $main::opt_trigger)
{
    $afg->setTrigger($main::opt_trigger);
}
if (defined $main::opt_sweep)
{
    $afg->setSweep($main::opt_sweep);
}
if (defined $main::opt_dc)
{
    $afg->setDC($main::opt_dc);
}
if (defined $main::opt_am)
{
    $afg->setAM($main::opt_am);
}
if (defined $main::opt_fm)
{
    $afg->setFM($main::opt_am);
}
if (defined $main::opt_on)
{
    $afg->setOutput(1);
}
if (defined $main::opt_off)
{
    $afg->setOutput(0);
}
if (defined $main::opt_arbread)
{
    my @data = $afg->arbRead($main::opt_arbread); # Reads the lot, can take a few seconds
    # @data is an array of 8192 integers -2047 to 2047
    # Write it to stdout
    foreach my $datum (@data)
    {
	print "$datum\n";
    }
}
if (@main::opt_arbwrite)
{
    my ($banknum, $filename) = @main::opt_arbwrite;

    my $fh;
    open($fh, $filename) || die "Cant open arbitrary data file $filename";
    my @data;
    while (my $line = <$fh>)
    {
	push(@data, int($line));
    }
    $afg->arbWrite($banknum, @data);
}
    
if (defined $main::opt_query)
{
    print $afg->sendAndRead($main::opt_query);
    print "\n";
}

if (defined $main::opt_postcommands)
{
    $afg->send($main::opt_postcommands);
}

if (defined $main::opt_errors)
{
    my @errors = $afg->getErrorsAsStrings();
    foreach my $error (@errors)
    {
	print "$error\n";
    }
}

sub usage
{
    print "usage: $0 [-h] 
          [-port [Prologix:[port[:baud:databits:parity:stopbits:handshake]]] 
          [-port LinuxGpib:[board_index]]
          [-address n]
          [-frequency n.nn[:HZ|KHZ|MHZ]]
          [-function SINE|SQUARE|TRIANGLE|DC|ARBITRARY]
          [-amplitude n.nn]
          [-mode CONT|TRIG|BURST|GATE|SYNT]
          [-offset n.nn]
          [-rate n.nn[units]]
          [-dc n.nn]
          [-nburst nn]
          [-trigger INT|EXT|MAN]
          [-sweep LIN|LOG|ARB|OFF]
          [-am -no-am]
          [-fm -no-fm]
          [-on]
          [-off]
          [-arbread 1|2]                   Output to stdout 8192 data points (-2047 to 2047), one per line
          [-arbwrite 1|2 filename]         One integer data point (-2047 to 2047) per line, up to 8192 points
          [-query gpibquerystring]
          [-precommands gpibcommandstring]
          [-postcommands gpibcommandstring]
          [-errors]\n";
    exit;
}
