#!/usr/bin/perl
#
# la1240.pl
#
# Control a Tektronix 1240 Logic Analzer by GPIB or Serial interface
# using the 1200C01 or 1200C02 Comm Packs
#
# The RS232C serial Comm Pack supports much the same commands
# as the GPIB. The command 'REMote' is required first to permit remote control mode when using serial
#
# To connect to RS232C Serial Comm Pack 1200C01:
# PC - USB cable - USB/Serial adapter - 9 to 25 pin adapter - NULL modem - 1200C01 Comm Pack
# Default RS232 settings for 1200C01 is 9600:8:N;1
#

use strict;
use Device::GPIB::Controller;
use Device::GPIB::Tektronix::LA1240;

use Getopt::Long;

my @options = 
    (
     'h',                   # Help, show usage
     'port=s',              # port[:baud:databits:parity:stopbits:handshake]
     'address=n',           # GPIB Address of the scope
     'debug',               # Show debugging info like bytes in and out

     'id',                  # Print ID
     'remote',              # Go to remote mode
     'local',               # Got to local mode
     'status',              # Print current status
     'events',              # List and delete all recent events
     'bell',                # Ring the bell
     'key',                 # Get the key number of the next keypress
     'start',               # Start acquisition
     'waitacquisition',     # Wait for acquisition to complete
     'stop',                # Stop acquisition
     'acqmem',              # Get acquisition memory
     'refmem',              # Get reference memory
     'init',                # Power-up init
     'test',                # Run self-test
     'getsetup',            # Get and print the instrument setup
     'loadsetup',           # Send a previously received setup to the instrument
     'loadacqmem',          # Send a previously received acqmem to the instrument
     'loadrefmem',          # Send a previously received refmem to the instrument
     
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

my $la = Device::GPIB::Tektronix::LA1240->new($d, $address);
exit unless $la;

if (defined $main::opt_precommands)
{
    $la->send($main::opt_precommands);
}

#######################3
# specific commands here
#######################3
if (defined $main::opt_remote)
{
    $la->remote();
}

if (defined $main::opt_local)
{
    $la->local();
}

if (defined $main::opt_id)
{
    my $id = $la->id();
    print "$id\n";
}

if (defined $main::opt_events)
{
    my @eventstrings = $la->getEventsAsStrings();
    foreach my $event (@eventstrings)
    {
	print "$event\n";
    }
}

if (defined $main::opt_status)
{
    my $status = $la->status();
    print "$status\n";
}

if (defined $main::opt_bell)
{
    $la->bell();
}

if (defined $main::opt_key)
{
    my $key = $la->key();
    if ($key != 0)
    {
	print "$key\n"; # Decimal keycode
    }
}

if (defined $main::opt_start)
{
    $la->start();
}

if (defined $main::opt_stop)
{
    $la->stop();
}

if (defined $main::opt_waitacquisition)
{
    $la->waitAcquisition();
}

if (defined $main::opt_acqmem)
{
    my $mem = $la->acqmem();
    print $mem;
}

if (defined $main::opt_refmem)
{
    my $mem = $la->refmem();
    print $mem;
}

if (defined $main::opt_getsetup)
{
    my $setup = $la->getSetup();
    print $setup;
}

if (defined $main::opt_init)
{
    $la->init();
}

if (defined $main::opt_test)
{
    $la->test();
}

# Seems the <loc> field identifies the actual memory involved
# For Serial interface, no ACQ, REF or INS command is required
# So these commands are essentially the same
if (defined $main::opt_loadacqmem)
{
    my $mem = do { local($/); <> }; # Slurp the file
    $la->loadAcqmem($mem);
}

if (defined $main::opt_loadrefmem)
{
    my $mem = do { local($/); <> }; # Slurp the file
    $la->loadRefmem($mem);
}

if (defined $main::opt_loadsetup)
{
    my $setup = do { local($/); <> }; # Slurp the file
    $la->loadSetup($setup);
}


if (defined $main::opt_query)
{
    print $la->sendAndRead($main::opt_query);
    print "\n";
}

if (defined $main::opt_postcommands)
{
    $la->send($main::opt_postcommands);
}

if (defined $main::opt_errors)
{
    my @errors = $la->getErrorsAsStrings();
    foreach my $error (@errors)
    {
	print "$error\n";
    }
}

#$la->displayAscii(11, 4, "Hello world");

sub usage
{
    print "usage: $0 [-h] 
          [-port [Prologix:[port[:baud:databits:parity:stopbits:handshake]]] 
          [-port Serial:[port[:baud:databits:parity:stopbits:handshake]]
          [-port LinuxGpib:[board_index]]
          [-address n]
	  [-id]
	  [-remote]
	  [-status]
	  [-events]
	  [-bell]
	  [-key]
	  [-start]
	  [-stop]
	  [-waitacquisition]
	  [-acqmem]
	  [-refmem]
	  [-getsetup]
	  [-loadacqmem]
	  [-loadrefmem]
	  [-loadsetup]
	  [-init]
	  [-test]
          [-query querystring]
          [-precommands ommandstring]
          [-postcommands commandstring]
          [-errors]\n";
    exit;
}
