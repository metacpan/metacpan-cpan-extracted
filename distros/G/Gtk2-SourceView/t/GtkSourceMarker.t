#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 7;

# $Id$

use Gtk2::SourceView;

my $table = Gtk2::SourceView::TagTable -> new();
my $buffer = Gtk2::SourceView::Buffer -> new($table);

my $marker = $buffer -> create_marker("Start", "start",
                                      $buffer -> get_start_iter());

$marker -> set_marker_type("start");
is($marker -> get_marker_type(), "start");


$marker -> set_marker_type(undef);
is($marker -> get_marker_type(), undef);

is($marker -> get_line(), 0);
is($marker -> get_name(), "Start");
is($marker -> get_buffer(), $buffer);

is($marker -> next(), undef);
is($marker -> prev(), undef);
