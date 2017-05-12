#!/usr/bin/perl

use strict;
use warnings;

use Gtk2::TestHelper tests => 2;

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
	my ($id) = $manager->get_scheme_ids();
	my $scheme = $manager->get_scheme($id);

	my $style = $scheme->get_style('def:comment');
	isa_ok($style, 'Gtk2::SourceView2::Style');
	my $copy = $style->copy();
	isa_ok($copy, 'Gtk2::SourceView2::Style');
}
