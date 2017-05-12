#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper tests => 6;

# $Id$

my $table = Gtk2::Table -> new(5, 5, 1);

$table -> resize(23, 42);

my $label = Gtk2::Label -> new("Bla");
my $button = Gtk2::Button -> new("Bla");

$table -> attach($label, 0, 1, 0, 1, "expand", "shrink", 1, 1);
$table -> attach_defaults($button, 0, 1, 1, 2);

$table -> set_row_spacing(1, 5);
is($table -> get_row_spacing(1), 5);

$table -> set_col_spacing(1, 5);
is($table -> get_col_spacing(1), 5);

$table -> set_row_spacings(5);
is($table -> get_default_row_spacing(), 5);

$table -> set_col_spacings(5);
is($table -> get_default_col_spacing(), 5);

$table -> set_homogeneous(0);
ok(! $table -> get_homogeneous());

SKIP: {
  skip 'new 2.22 stuff', 1
    unless Gtk2->CHECK_VERSION(2, 22, 0);

  my ($w, $h) = $table -> get_size();
  ok (defined $w && defined $h);
}

__END__

Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
