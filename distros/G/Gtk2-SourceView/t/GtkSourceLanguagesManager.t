#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 4;

# $Id: GtkSourceLanguagesManager.t,v 1.1 2005/08/11 18:01:56 kaffeetisch Exp $

use Gtk2::SourceView;

my $manager = Gtk2::SourceView::LanguagesManager -> new();
isa_ok($manager, "Gtk2::SourceView::LanguagesManager");

my @languages = $manager -> get_available_languages();
isa_ok($languages[0], "Gtk2::SourceView::Language");

isa_ok($manager -> get_language_from_mime_type("application/x-perl"),
       "Gtk2::SourceView::Language");

my @dirs = $manager -> get_lang_files_dirs();
ok(@dirs > 0);
