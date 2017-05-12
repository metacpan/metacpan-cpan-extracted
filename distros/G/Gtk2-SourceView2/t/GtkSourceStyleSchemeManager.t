#!/usr/bin/perl

use strict;
use warnings;

use Gtk2::TestHelper tests => 10;

use FindBin;
use lib "$FindBin::Bin";
use my_helper;

use Glib qw(TRUE FALSE);
use Gtk2::SourceView2;

exit tests();


sub tests {
	test_constructors();
	test_properties();
	return 0;
}


sub test_constructors {
	my $manager;
	
	$manager = Gtk2::SourceView2::StyleSchemeManager->new();
	isa_ok($manager, 'Gtk2::SourceView2::StyleSchemeManager');

	$manager = Gtk2::SourceView2::StyleSchemeManager->get_default();
	isa_ok($manager, 'Gtk2::SourceView2::StyleSchemeManager');
}


sub test_properties {
	my $manager = Gtk2::SourceView2::StyleSchemeManager->get_default();

	ok(scalar($manager->get_scheme_ids), "get_scheme_ids");
	my @path = $manager->get_search_path;
	ok(scalar(@path), "get_search_path");
	
	my ($scheme_id) = $manager->get_scheme_ids;
	my $scheme = $manager->get_scheme($scheme_id);
	isa_ok($scheme, 'Gtk2::SourceView2::StyleScheme');

	# Clear the search path
	$manager->set_search_path();
	is_deeply(
		[ $manager->get_search_path ],
		[  ],
		"set_search_path() clear"
	);

	$manager->set_search_path('a', 'b');
	is_deeply(
		[ $manager->get_search_path ],
		[ 'a', 'b' ],
		"set_search_path(a, b)"
	);

	$manager->append_search_path('c');
	is_deeply(
		[ $manager->get_search_path ],
		[ 'a', 'b', 'c' ],
		"append_search_path(c)"
	);

	$manager->prepend_search_path('0');
	is_deeply(
		[ $manager->get_search_path ],
		[ 0, 'a', 'b', 'c' ],
		"prepend_search_path(0)"
	);


	# Reset the search path
	$manager->set_search_path(undef);
	is_deeply(
		[ $manager->get_search_path ],
		[ @path ],
		"set_search_path(undef) reset"
	);

	$manager->force_rescan();
}
