#!/usr/bin/perl
#
# gpib.pl
#
# Act like a GPIB device
# Connects to a controller and puts it in device mode
# listens for messages from the controller and replies
# not yet working correctly with Linux-GPIB

use strict;
use Device::GPIB::Controller;
use Device::GPIB::Generic;

use Getopt::Long;
my @options = 
    (
     'h',                   # Help, show usage
     'port=s',              # port[:baud:databits:parity:stopbits:handshake]
     'address=n',           # Our GPIB device Address
     'debug',               # Show debugging info like bytes in and out
     'id=s',                # Automatic response to ID? requests
    );

&GetOptions(@options) || &usage;
&usage if $main::opt_h;
my $port = '/dev/ttyUSB0';
my $address = 7;


$port = $main::opt_port if defined $main::opt_port;
$address = $main::opt_address if defined $main::opt_address;
Device::GPIB::Controller::enableDebug(1) if $main::opt_debug;

my $d = Device::GPIB::Controller->new($port);
exit unless $d;

my $gpib = Device::GPIB::Generic->new($d, $address);
exit unless $gpib;

$gpib->actAsDevice();


while (1)
{
    my $request = $gpib->read_to_eol();
    $d->debug("request: $request\n");
    if ($request =~ /^id\?/i && defined $main::opt_id)
    {
	$d->send($main::opt_id);
    }
    # else do you own thing here?
    # Could we pipe to another program and wait for a response?
}
