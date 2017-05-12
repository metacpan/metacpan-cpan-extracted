#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper tests => 19;

# $Id$

package EditableTest;

use Test::More;

use Glib::Object::Subclass
  Gtk2::Label::,
  interfaces => [ Gtk2::CellEditable:: ];

sub START_EDITING {
  my ($editable, $event) = @_;

  isa_ok($editable, "EditableTest");
  isa_ok($editable, "Gtk2::Label");
  isa_ok($editable, "Gtk2::CellEditable");

  ok(not defined $event or ref $event eq "Gtk2::Gdk::Event::Button");
}

sub EDITING_DONE {
  my ($editable, $event) = @_;

  isa_ok($editable, "EditableTest");
  isa_ok($editable, "Gtk2::Label");
  isa_ok($editable, "Gtk2::CellEditable");
}

sub REMOVE_WIDGET {
  my ($editable, $event) = @_;

  isa_ok($editable, "EditableTest");
  isa_ok($editable, "Gtk2::Label");
  isa_ok($editable, "Gtk2::CellEditable");
}

package main;

my $editable = EditableTest -> new();
isa_ok($editable, "Gtk2::CellEditable");

$editable -> start_editing();
$editable -> start_editing(undef);
$editable -> start_editing(Gtk2::Gdk::Event -> new("button-press"));
$editable -> editing_done();
$editable -> remove_widget();

__END__

Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
