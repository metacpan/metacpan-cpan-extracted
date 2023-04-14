#!/usr/bin/perl
#
# mi5010.pl
#
# Control a Tektronix MI5010 and sub mudules over GPIB

use strict;
use Device::GPIB::Controller;
use Device::GPIB::Tektronix::MI5010;

use Getopt::Long;

my @options = 
    (
     'h',                   # Help, show usage
     'port=s',              # port[:baud:databits:parity:stopbits:handshake]
     'address=n',           # GPIB Address of the scope
     'debug',               # Show debugging info like bytes in and out
     'setlocaltime=i',      # Set the local time and the power line freq in Hz
     'query=s',             # General query and print result to stdout
     'precommands=s',       # List of GPIB and instrument commands to send before anything else
     'postcommands=s',      # List of GPIB and instrument commands to send after anything else
     'errors',              # Print any error
    );

&GetOptions(@options) || &usage;
&usage if $main::opt_h;
my $port = '/dev/ttyUSB0';
my $address = 16;

$port = $main::opt_port if defined $main::opt_port;
$address = $main::opt_address if defined $main::opt_address;
$Device::GPIB::Controller::debug = 1 if $main::opt_debug;

my $d = Device::GPIB::Controller->new($port);

exit unless $d;

my $mi = Device::GPIB::Tektronix::MI5010->new($d, $address);
exit unless $mi;

if (defined $main::opt_precommands)
{
    $mi->send($main::opt_precommands);
}
if (defined $main::opt_setlocaltime)
{
    $mi->setTime(undef, $main::opt_setlocaltime);
}

#my ($time, $hz) = $mi->getTime();
#print "got $time and $hz\n";

# Test relay scanner commands
#$mi->send('SEL 2;ope all;clo 1,2,3,4,5,6,7');

# Until time, foir use with 'WAI UNTI'
#$mi->setUntil(time() + 10);
# my $until = $mi->getUntil();
# print "until $x\n"; # eg 14:33:19

#$mi->select(1);
#$mi->send('CONVERT');

if (defined $main::opt_query)
{
    print $mi->sendAndRead($main::opt_query);
    print "\n";
}

if (defined $main::opt_postcommands)
{
    $mi->send($main::opt_postcommands);
}

if (defined $main::opt_errors)
{
    my @errors = $mi->getErrorsAsStrings();
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
          [-setlocaltime 50|60]
          [-query gpibquerystring]
          [-precommands gpibcommandstring]
          [-postcommands gpibcommandstring]
          [-errors]\n";
    exit;
}
