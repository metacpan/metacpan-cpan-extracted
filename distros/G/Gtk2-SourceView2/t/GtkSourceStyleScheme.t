#!/usr/bin/perl

use strict;
use warnings;

use Gtk2::TestHelper tests => 8;

use FindBin;
use lib "$FindBin::Bin";
use my_helper;

use Glib qw(TRUE FALSE);
use Gtk2::SourceView2;

exit tests();


sub tests {
	test_properties();
	return 0;
}


sub test_properties {
	my $manager = Gtk2::SourceView2::StyleSchemeManager->get_default();
	my $scheme = $manager->get_scheme('classic');
	isa_ok($scheme, 'Gtk2::SourceView2::StyleScheme');

	is($scheme->get_id, 'classic', "get_id");
	ok($scheme->get_name, "get_name");
	ok($scheme->get_description, "get_description");
	ok($scheme->get_filename =~ m(/classic\.xml), "get_filename");
	is_deeply(
		[ $scheme->get_authors ],
		[ 'GtkSourceView team' ], 
		"get_id"
	);

	isa_ok($scheme->get_style('def:comment'), 'Gtk2::SourceView2::Style', "get_style");
	is($scheme->get_style('do-no-exist'), undef, "get_style, doesn't exist");
}
