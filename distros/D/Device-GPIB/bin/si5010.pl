#!/usr/bin/perl
#
# si5010.pl
#
# Control a Tektronix SI5010 over GPIB

use strict;
use Device::GPIB::Controller;
use Device::GPIB::Tektronix::SI5010;

use Getopt::Long;

my @options = 
    (
     'h',                   # Help, show usage
     'port=s',              # port[:baud:databits:parity:stopbits:handshake]
     'address=n',           # GPIB Address of the scope
     'debug',               # Show debugging info like bytes in and out
     'conf=s',              # 4 numbers, comma sep, adding to 16
     'close=s',             # Up to 16 comma sep relay numbers
     'open=s',              # Up to 16 comma sep relay numbers
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

my $si = Device::GPIB::Tektronix::SI5010->new($d, $address);
exit unless $si;

if (defined $main::opt_precommands)
{
    $si->send($main::opt_precommands);
}

if (defined $main::opt_conf)
{
    $si->setConf(split(/,/, $main::opt_conf));
}

if (defined $main::opt_close)
{
    $si->setClosed(split(/,/, $main::opt_close));
}

if (defined $main::opt_open)
{
    $si->setOpen(split(/,/, $main::opt_open));
}

#my $x = $si->getArm();
#print "its $x\n";


if (defined $main::opt_query)
{
    print $si->sendAndRead($main::opt_query);
    print "\n";
}

if (defined $main::opt_postcommands)
{
    $si->send($main::opt_postcommands);
}

if (defined $main::opt_errors)
{
    my @errors = $si->getErrorsAsStrings();
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
          [-conf 4commaseparatednumbersaddingupto16]
          [-open commaseparatedrelaylist]
          [-close commaseparatedrelaylist]
          [-query gpibquerystring]
          [-precommands gpibcommandstring]
          [-postcommands gpibcommandstring]
          [-errors]\n";
    exit;
}
