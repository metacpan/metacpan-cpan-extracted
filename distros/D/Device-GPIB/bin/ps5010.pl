#!/usr/bin/perl
#
# ps5010.pl
#
# Control a Tektronix PS5010 over GPIB

use strict;
use Device::GPIB::Controller;
use Device::GPIB::Tektronix::PS5010;
#use Device::GPIB::Tektronix::DM5110;

use Getopt::Long;

my @options = 
    (
     'h',                   # Help, show usage
     'port=s',              # port[:baud:databits:parity:stopbits:handshake]
     'address=n',           # GPIB Address of the scope
     'debug',               # Show debugging info like bytes in and out
     'vpositive=f',         # Set V Positive
     'vnegative=f',         # Set V Negative
     'vlogic=f',            # Set V Logic
     'vtrack=f',            # Set V positive and negative tracking
     'ipositive=f',         # Set I Positive
     'inegative=f',         # Set I Negative
     'ilogic=f',            # Set I Logic
     'itrack=f',            # Set I positive and negative tracking
     'on',                  # Turn outputs on
     'off',                 # Turn outputs off
     'query=s',             # General query and print result to stdout
     'precommands=s',       # List of GPIB and instrument commands to send before anything else
     'postcommands=s',      # List of GPIB and instrument commands to send after anything else
     'errors',              # Print any error
    );
&GetOptions(@options) || &usage;
&usage if $main::opt_h;
my $port = '/dev/ttyUSB0';
my $address = 23;

$port = $main::opt_port if defined $main::opt_port;
$address = $main::opt_address if defined $main::opt_address;
$Device::GPIB::Controller::debug = 1 if $main::opt_debug;

my $d = Device::GPIB::Controller->new($port);

exit unless $d;

my $ps = Device::GPIB::Tektronix::PS5010->new($d, $address);
exit unless $ps;

#my $meter = Device::GPIB::Tektronix::DM5110->new($d, 22);
#exit unless $meter;

#my $v = $ps->getVPositive();
#print "POS: $v\n";
#$ps->setVPositive(1.23);
#$v = $ps->getVPositive();
#print "POS: $v\n";

#my $v = $ps->getVNegative();
#print "NEG: $v\n";
#$ps->setVNegative(2.22);
#$v = $ps->getVNegative();
#print "NEG: $v\n";

#my $v = $ps->getVLogic();
#print "LOGIC: $v\n";

#$ps->setVLogic(5.11);
#$v = $ps->getVLogic();
#print "LOGIC: $v\n";

#$ps->setVTrack(3.33);

#my $value = $meter->measure('VDC');
#print "value is $value\n";

#    my $value = $ps->test();
#    print "value is $value\n";


if (defined $main::opt_precommands)
{
    $ps->send($main::opt_precommands);
}
if (defined $main::opt_vpositive)
{
    $ps->setVPositive($main::opt_vpositive);
}
if (defined $main::opt_ipositive)
{
    $ps->setIPositive($main::opt_ipositive);
}
if (defined $main::opt_vnegative)
{
    $ps->setVNegative($main::opt_vnegative);
}
if (defined $main::opt_inegative)
{
    $ps->setINegative($main::opt_inegative);
}
if (defined $main::opt_vlogic)
{
    $ps->setVLogic($main::opt_vlogic);
}
if (defined $main::opt_ilogic)
{
    $ps->setILogic($main::opt_ilogic);
}
if (defined $main::opt_vtrack)
{
    $ps->setVTrack($main::opt_vtrack);
}
if (defined $main::opt_itrack)
{
    $ps->setITrack($main::opt_itrack);
}
if (defined $main::opt_on)
{
    $ps->on();
}
if (defined $main::opt_off)
{
    $ps->off();
}
if (defined $main::opt_query)
{
    print $ps->sendAndRead($main::opt_query);
    print "\n";
}
if (defined $main::opt_postcommands)
{
    $ps->send($main::opt_postcommands);
}

if (defined $main::opt_errors)
{
    my @errors = $ps->getErrorsAsStrings();
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
          [-vpositive n.nn]
          [-vnegative n.nn]
          [-vlogic n.nn]
          [-vtrack n.nn]
          [-ipositive n.nn]
          [-inegative n.nn]
          [-ilogic n.nn]
          [-itrack n.nn]
          [-on]
          [-off]
          [-query gpibquerystring]
          [-precommands gpibcommandstring]
          [-postcommands gpibcommandsstring]
          [-errors]\n";
    exit;
}
