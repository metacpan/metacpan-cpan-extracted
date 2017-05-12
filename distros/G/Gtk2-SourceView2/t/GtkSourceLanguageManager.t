#!/usr/bin/perl

use strict;
use warnings;

use Gtk2::TestHelper tests => 17;

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
	my $lm;
	
	$lm = Gtk2::SourceView2::LanguageManager->new();
	isa_ok($lm, 'Gtk2::SourceView2::LanguageManager');

	$lm = Gtk2::SourceView2::LanguageManager->get_default();
	isa_ok($lm, 'Gtk2::SourceView2::LanguageManager');
}


sub test_properties {
	my $lm = Gtk2::SourceView2::LanguageManager->get_default();

	ok(scalar($lm->get_language_ids), "get_language_ids");

	# Get language
	my $language = $lm->get_language('perl');
	isa_ok($language, 'Gtk2::SourceView2::Language');
	is($language->get_id, 'perl', "Got perl");

	$language = $lm->get_language('emo-perl');
	is($language, undef, "No such language emo-perl");


	# Guess language
	$language = $lm->guess_language("$FindBin::Bin/my_helper.pm", undef);
	isa_ok($language, 'Gtk2::SourceView2::Language');
	is($language->get_id, 'perl', "Got perl");

	$language = $lm->guess_language("sample.c");
	isa_ok($language, 'Gtk2::SourceView2::Language');
	is($language->get_id, 'c', "Got C");

	$language = $lm->guess_language(undef, 'text/x-c');
	isa_ok($language, 'Gtk2::SourceView2::Language');
	is($language->get_id, 'c', "Got c");

	
	# Take a new LanguageManager an destroy it's search path
	$lm = Gtk2::SourceView2::LanguageManager->new();
	my @path = $lm->get_search_path;
	ok(scalar(@path) > 0, "original search path has values");

	# Clear the search path
	$lm->set_search_path();
	is_deeply(
		[ $lm->get_search_path ],
		[ ],
		"set_search_path() clear"
	);

	$lm->set_search_path('a');
	is_deeply(
		[ $lm->get_search_path ],
		[ 'a' ],
		"set_search_path(a)"
	);

	$lm->set_search_path('a', 'b');
	is_deeply(
		[ $lm->get_search_path ],
		[ 'a', 'b' ],
		"set_search_path(a, b)"
	);


	# Reset the search path
	$lm->set_search_path(undef);
	is_deeply(
		[ $lm->get_search_path ],
		[ @path ],
		"set_search_path(undef) reset"
	);
}
