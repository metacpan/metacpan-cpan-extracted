#!/usr/bin/perl

use strict;
use warnings;

use Gtk2::TestHelper tests => 12;

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

	my $lm = Gtk2::SourceView2::LanguageManager->get_default();
	isa_ok($lm, 'Gtk2::SourceView2::LanguageManager');
	
	my $language = $lm->get_language('perl');
	isa_ok($language, 'Gtk2::SourceView2::Language');

	is($language->get_id, 'perl', "get_id");
	is($language->get_name, 'Perl', "get_name");
	ok($language->get_section, "get_section");
	is($language->get_hidden, FALSE, "get_hidden");

	is($language->get_metadata('line-comment-start'), '#', "get_metadata");
	is($language->get_metadata('doest-no-exist'), undef, "get_metadata undef");

	is($language->get_style_name('perl:pod'), 'POD', "get_style_name");

	is_deeply(
		[ sort $language->get_mime_types ],
		[ sort ('text/x-perl', 'application/x-perl') ],
		"get_mime_types"
	);

	is_deeply(
		[ sort $language->get_globs ],
		[ sort ('*.pl', '*.pm', '*.al', '*.perl') ],
		"get_globs"
	);

	ok(scalar($language->get_style_ids), "get_style_ids");
}
