#!/usr/bin/perl
#
# hp8904a.pl
#
# Control a HP8904A over GPIB
# Hmmmm, theres nothing you can do here thats not in gpib.pl
#
# Some sample commands:
#     Channel A: float 1 off, 1234.5Hz, 1.25V, 90 deg phase, ramp:
# perl -I lib bin/hp8904a.pl -precommands 'PS;GM0;FC1OF;FRA1234.5HZ;APA1.25VL;PHA90DG;WFARA'
#

use strict;
use Device::GPIB::Controller;
use Device::GPIB::HP::HP8904A;
use Getopt::Long;

my @options = 
    (
     'h',                   # Help, show usage
     'port=s',              # port[:baud:databits:parity:stopbits:handshake]
     'address=n',           # GPIB Address of the scope
     'debug',               # Show debugging info like bytes in and out
     'query=s',             # General query and print result to stdout
     'precommands=s',       # List of GPIB and instrument commands to send before anything else
     'postcommands=s',      # List of GPIB and instrument commands to send after anything else
    );

&GetOptions(@options) || &usage;
&usage if $main::opt_h;
my $port = '/dev/ttyUSB0';
my $address = 26;

$port = $main::opt_port if defined $main::opt_port;
$address = $main::opt_address if defined $main::opt_address;
$Device::GPIB::Controller::debug = 1 if $main::opt_debug;

my $d = Device::GPIB::Controller->new($port);

exit unless $d;

my $synthesizer = Device::GPIB::HP::HP8904A->new($d, $address);
exit unless $synthesizer;

if (defined $main::opt_precommands)
{
    $synthesizer->send($main::opt_precommands);
}

if (defined $main::opt_query)
{
    print $synthesizer->sendAndRead($main::opt_query);
    print "\n";
}

if (defined $main::opt_postcommands)
{
    $synthesizer->send($main::opt_postcommands);
}


sub usage
{
    print "usage: $0 [-h]
          [-port [Prologix:[port[:baud:databits:parity:stopbits:handshake]]] 
          [-port LinuxGpib:[board_index]]
    	  [-address n]
          [-query gpibquerystring]
          [-precommands gpibcommandstring]
          [-postcommands gpibcommandstring]\n";
    exit;
}

