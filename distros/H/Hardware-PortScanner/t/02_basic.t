#!/usr/bin/perl -w

use strict;
use Test::More;
use Data::Dumper;
$Data::Dumper::Useqq = 1;



our $serial_obj;
our @available_ports;
our $can_get_connection;
our $ports_scanned;

my ($databits, $parity, $stopbits, $handshake, $setting, @settings);

foreach $databits (qw/5 6 7 8/) {
	foreach $parity (qw/N E O/) {
		foreach $stopbits (qw/1 2/) {
			#foreach $handshake (qw/N R X s/) {  # This locked up some com ports. See bugs/issues in docs
			foreach $handshake (qw/s/) {

					$setting = sprintf("%s%s%s%s",	$databits,
																$parity,
																$stopbits,
																($handshake eq "s" ? "" : $handshake));
					push(@settings, $setting);
			}
		}
	}
}
		

# print "Settings: " . join(", ", @settings) . "\n";

plan tests => 5;

eval { require Hardware::PortScanner };

if ($@) {
	ok(0, "Compilation of Hardware::PortScanner");
	diag("Reason: $@");
	BAIL_OUT("Compilation of Hardware::PortScanner failed!");
}
ok(1, "Compilation of Hardware::PortScanner");


$serial_obj = Hardware::PortScanner->new();

@available_ports = $serial_obj->available_com_ports();

ok (scalar(@available_ports) > 0, "Available Com Port") or diag "Cannot find even one available com port on this machine.  Assuming the worst since is hard to test this module's functionality without one";



eval { $serial_obj->scan_ports(
							 COM => \@available_ports,
  	                   SETTING => [ $setting ],
  	                   TEST_STRING => "TEST\n",
  	                   VALID_REPLY_RE => '.*',
				MAX_WAIT => .2
  	                 );
		};

$can_get_connection = 1;

if (! ok (! $@, "Basic Settings Test"))
{ 
	diag("Scan Test Failed: $@");
	$can_get_connection = 0;
}

if (! ok (scalar($serial_obj->found_devices) != 0, "Find Anything Test"))
{
	diag("Tried to find anything (even no responses) and found nothing - suggests something wrong or no available ports");
	$can_get_connection = 0;
}

SKIP: {
   skip "Can't get serial connection", 1 unless ($can_get_connection);


	$serial_obj = Hardware::PortScanner->new(MAX_PORT => "com5");

	eval { $serial_obj->scan_ports(
  					                   TEST_STRING => "TEST\n",
  	        					           VALID_REPLY_RE => '.*'
  	                					 );
			};

	$ports_scanned = scalar(grep { $_ =~ "^Scan Port.*[@]" } $serial_obj->scan_log);

	ok ($ports_scanned == 5, "MAX_PORT new test") or
		diag("Limiting Max_Ports failed to limit scans ($ports_scanned)");

 };









