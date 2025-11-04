#!/usr/bin/perl
#
# afg310.pl
#
# Control a Tektronix AFG310 over GPIB

use strict;
use Device::GPIB::Controller;
use Device::GPIB::Tektronix::AFG310;

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
my $address = 1;

$port = $main::opt_port if defined $main::opt_port;
$address = $main::opt_address if defined $main::opt_address;
$Device::GPIB::Controller::debug = 1 if $main::opt_debug;

my $d = Device::GPIB::Controller->new($port);

exit unless $d;

my $afg = Device::GPIB::Tektronix::AFG310->new($d, $address);
exit unless $afg;

if (defined $main::opt_precommands)
{
    $afg->send($main::opt_precommands);
}

#######################3
# specific commands here
#######################3


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
	  .....
          [-query gpibquerystring]
          [-precommands gpibcommandstring]
          [-postcommands gpibcommandstring]
          [-errors]\n";
    exit;
}
