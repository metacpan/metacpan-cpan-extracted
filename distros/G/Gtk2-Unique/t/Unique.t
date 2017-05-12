#!/usr/bin/perl

use strict;
use warnings;

use Gtk2::TestHelper tests => 12;

use Gtk2::Unique;

exit tests();


sub tests {
	test_version();
	return 0;
}


sub test_version {
	ok($Gtk2::Unique::VERSION, "Module loaded");


	ok(Gtk2::Unique::VERSION, "Version");
	ok(Gtk2::Unique::VERSION_HEX, "Version hex");
	ok(Gtk2::Unique::API_VERSION, "API version");
	ok(Gtk2::Unique::PROTOCOL_VERSION, "Protocol version");
	ok(Gtk2::Unique::DEFAULT_BACKEND, "Default backend");

	ok(defined Gtk2::Unique::MAJOR_VERSION, "MAJOR_VERSION exists");
	ok(defined Gtk2::Unique::MINOR_VERSION, "MINOR_VERSION exists");
	ok(defined Gtk2::Unique::MICRO_VERSION, "MICRO_VERSION exists");

	ok (Gtk2::Unique->CHECK_VERSION(0,0,0), "CHECK_VERSION pass");
	ok (!Gtk2::Unique->CHECK_VERSION(50,0,0), "CHECK_VERSION fail");

	my @version = Gtk2::Unique->GET_VERSION_INFO;
	my @expected = (
		Gtk2::Unique::MAJOR_VERSION,
		Gtk2::Unique::MINOR_VERSION,
		Gtk2::Unique::MICRO_VERSION,
	);
	is_deeply(\@version, \@expected, "GET_VERSION_INFO");
}
