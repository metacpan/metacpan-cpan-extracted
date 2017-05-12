#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 4;

# $Id: GtkSourceStyleScheme.t,v 1.1 2005/08/11 18:01:56 kaffeetisch Exp $

use Gtk2::SourceView;

SKIP: {
  skip "style scheme stuff", 4
    unless (0); # FIXME

  my $scheme = Gtk2::SourceView::StyleScheme -> get_default();
  isa_ok($scheme, "Gtk2::SourceView::StyleScheme");
  isa_ok($scheme -> get_tag_style(), "Gtk2::SourceView::TagStyle");
  is($scheme -> get_name(), "Default");

  warn join ", ", $scheme -> get_style_names();
}
