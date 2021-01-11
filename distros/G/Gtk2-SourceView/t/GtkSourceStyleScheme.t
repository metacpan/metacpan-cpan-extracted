#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 4;

# $Id$

use Gtk2::SourceView;

my $scheme = Gtk2::SourceView::StyleScheme -> get_default();
isa_ok($scheme, "Gtk2::SourceView::StyleScheme");
isa_ok($scheme -> get_tag_style("Comment"), "Gtk2::SourceView::TagStyle");
is($scheme -> get_name(), "Default");

my @names = $scheme -> get_style_names();
ok(@names > 0);
