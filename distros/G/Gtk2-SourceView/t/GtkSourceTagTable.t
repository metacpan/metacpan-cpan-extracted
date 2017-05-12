#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 1;

# $Id: GtkSourceTagTable.t,v 1.1 2005/08/11 18:01:56 kaffeetisch Exp $

use Gtk2::SourceView;

my $table = Gtk2::SourceView::TagTable -> new();
isa_ok($table, "Gtk2::SourceView::TagTable");

my @tags = (Gtk2::TextTag -> new("bla"),
            Gtk2::TextTag -> new("ble"),
            Gtk2::TextTag -> new("bli"),
            Gtk2::TextTag -> new("blo"),
            Gtk2::TextTag -> new("blu"));

$table -> add_tags(@tags);
$table -> remove_source_tags();
