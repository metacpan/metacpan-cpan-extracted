#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper tests => 23;

# $Id$

my $item = Gtk2::MenuItem -> new();
isa_ok($item, "Gtk2::MenuItem");

$item = Gtk2::MenuItem -> new("_Bla");
isa_ok($item, "Gtk2::MenuItem");

$item = Gtk2::MenuItem -> new_with_label("Bla");
isa_ok($item, "Gtk2::MenuItem");

$item = Gtk2::MenuItem -> new_with_mnemonic("Bla");
isa_ok($item, "Gtk2::MenuItem");

$item -> select();
$item -> deselect();
$item -> toggle();

$item -> activate();

$item -> set_right_justified(1);
is($item -> get_right_justified(), 1);

my $menu = Gtk2::Menu -> new();

$item -> set_submenu($menu);
is($item -> get_submenu(), $menu);

SKIP: {
  skip '2.12 stuff', 1
    unless Gtk2 -> CHECK_VERSION(2, 12, 0);

  $item -> set_submenu(undef);
  is($item -> get_submenu(), undef);
}

$item -> remove_submenu();
$item -> set_accel_path("<bla/bla/bla>");

# Ensure that both spellings of the signal name get the custom marshaller.
foreach my $signal_name (qw/toggle_size_request toggle-size-request/) {
  my $id = $item -> signal_connect($signal_name => sub {
    is (shift, $item, $signal_name);
    is (shift, "bla", $signal_name);
    return 23;
  }, "bla");
  is ($item -> toggle_size_request(), 23);
  $item -> signal_handler_disconnect ($id);
}

$item -> signal_connect(toggle_size_allocate => sub {
  is (shift, $item);
  is (shift, 23);
  is (shift, "bla");
}, "bla");

$item -> toggle_size_allocate(23);

SKIP: {
  skip 'new 2.14 stuff', 1
    unless Gtk2->CHECK_VERSION(2, 14, 0);

  my $item = Gtk2::MenuItem -> new();
  $item -> set_accel_path('<bla>/bla/bla');
  is ($item -> get_accel_path(), '<bla>/bla/bla');
}

SKIP: {
  skip 'new 2.16 stuff', 2
    unless Gtk2->CHECK_VERSION(2, 16, 0);

  my $item = Gtk2::MenuItem->new ("_foo");
  $item->set_use_underline (TRUE);
  is ($item->get_use_underline, TRUE, '[gs]et_use_underline');
  $item->set_label ('Test');
  is ($item->get_label, 'Test');
}

#-----------------------------------------------------------------------------
# circular ref between MenuItem and child AccelLabel
#
# These tests verify what's described in the pod of Gtk2::MenuItem->new,
# ->new_with_label and ->new_with_mnemonic, namely that circa Gtk 2.18 an
# item created with a label gets a circular reference up from the child
# AccelLabel "accel-widget" property and thus needs ->destroy or similar.
#
# If the MenuItems here are in fact destroyed by weakening then that'd be
# fine for the code, but the docs would be wrong, for some or other Gtk
# version.
#
require Scalar::Util;
{
  my $item = Gtk2::MenuItem->new("foo");
  Scalar::Util::weaken ($item);
  ok ($item, 'new("foo") not destroyed by weakening (correctness of the docs)');
  if ($item) { $item->destroy; }
}
{
  my $item = Gtk2::MenuItem->new_with_label("foo");
  Scalar::Util::weaken ($item);
  ok ($item, 'new_with_label("foo") not destroyed by weakening (correctness of the docs)');
  if ($item) { $item->destroy; }
}
{
  my $item = Gtk2::MenuItem->new_with_mnemonic("foo");
  Scalar::Util::weaken ($item);
  ok ($item, 'new_with_mnemonic("foo") not destroyed by weakening (correctness of the docs)');
  if ($item) { $item->destroy; }
}

SKIP: {
  # "label" property new in Gtk 2.16
  skip 'new 2.16 stuff', 1
    unless Gtk2->CHECK_VERSION(2, 16, 0);

  my $item = Gtk2::MenuItem->new;
  $item->set (label => "foo");
  Scalar::Util::weaken ($item);
  ok ($item, 'set(label=>"foo") not destroyed by weakening (correctness of the docs)');
  if ($item) { $item->destroy; }
}

__END__

Copyright (C) 2003, 2010 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
