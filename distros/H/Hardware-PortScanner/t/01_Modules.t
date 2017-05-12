#!/usr/bin/perl -w

use strict;
use Test::More; 

our $serial_module;
our @serial_methods = (qw/new baudrate databits stopbits handshake parity/);

our $num_tests = 2 + scalar(@serial_methods);

plan tests => $num_tests;

if ($^O eq "MSWin32")
{
	if (! use_ok( 'Win32::SerialPort' ))
	{
		BAIL_OUT("This module requires Win32::SerialPort which appears not to be installed\n");
	}

	$serial_module = "Win32::SerialPort";
}
else
{
	# Assuming UNIX at this point
	# which might not really matter in this
	# module in fact exists

	if (! use_ok( 'Device::SerialPort' ) )
	{
		BAIL_OUT("This module requires Device::SerialPort which appears not to be installed\n");
	}
	$serial_module = "Device::SerialPort";

}

foreach my $meth (@serial_methods) {
   can_ok($serial_module, $meth) or diag("This module needs \"$serial_module\" to have the \"$meth\" method");
}

eval { require Hardware::PortScanner };

if ($@) {
	ok(0, "Compilation of Hardware::PortScanner");
	diag("Reason: $@");
	BAIL_OUT("Compilation of Hardware::PortScanner failed!");
}
ok(1, "Compilation of Hardware::PortScanner");

