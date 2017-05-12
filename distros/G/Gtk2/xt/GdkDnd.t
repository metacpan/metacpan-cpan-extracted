#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper tests => 26;

# $Id$

my $window = Gtk2::Window -> new();
$window -> realize();
$window -> show_now;

###############################################################################

my $context = Gtk2::Gdk::DragContext -> new();
isa_ok($context, "Gtk2::Gdk::DragContext");

my @targets = (Gtk2::Gdk::Atom -> new("target-string"),
               Gtk2::Gdk::Atom -> new("target-bitmap"));

$context = Gtk2::Gdk::DragContext -> begin($window -> window(), @targets);
isa_ok($context, "Gtk2::Gdk::DragContext");

my ($destination, $protocol);

SKIP: {
  skip("GdkScreen is new in 2.2", 2)
    unless Gtk2 -> CHECK_VERSION(2, 2, 0);

  ($destination, $protocol) =  $context -> find_window_for_screen($window -> window(), Gtk2::Gdk::Screen -> get_default(), 0, 0);

  ok(not defined $destination or ref $destination eq "Gtk2::Gdk::Window");
  ok(not defined $destination or $protocol);
}

$context -> abort(0);

###############################################################################

$context = Gtk2::Gdk::DragContext -> begin($window -> window(), @targets);
isa_ok($context, "Gtk2::Gdk::DragContext");

ok($context -> protocol());
is($context -> is_source(), 1);
is($context -> source_window(), $window -> window());
is_deeply([map { $_ -> name() } $context -> targets()],
          [map { $_ -> name() } @targets]);
isa_ok(($context -> targets())[0], "Gtk2::Gdk::Atom");

($destination, $protocol) = $context -> find_window($window -> window(), 0, 0);

ok(not defined $destination or ref $destination eq "Gtk2::Gdk::Window");
ok(not defined $destination or $protocol);

SKIP: {
  skip "find_window returned no destination window, skipping the tests that need one", 9
    unless defined $destination;

  # FIXME: what about the return value?
  $context -> motion($destination, $protocol, 100, 100, [qw(copy)], [qw(copy move)], 0);

  ok($context -> actions() == [qw(copy move)]);
  ok($context -> suggested_action() == qw(copy));
  is($context -> start_time(), 0);

  SKIP: {
    skip "can't do x11 stuff on this platform", 2
      if $^O eq 'MSWin32';

    is_deeply([Gtk2::Gdk::DragContext -> get_protocol($destination -> get_xid())],
              [$destination -> get_xid(), $protocol]);

    skip("get_protocol_for_display is new in 2.2", 1)
      unless Gtk2->CHECK_VERSION (2, 2, 0);

    is_deeply([Gtk2::Gdk::DragContext -> get_protocol_for_display(Gtk2::Gdk::Display -> get_default(), $destination -> get_xid())],
              [$destination -> get_xid(), $protocol]);
  }

  is($context -> dest_window(), $destination);
  my $selection = $context -> get_selection();
  SKIP: {
    skip "selection test: get_selection returned undef", 1
      unless defined $selection;
    isa_ok($selection, "Gtk2::Gdk::Atom");
  }

  $context -> status(qw(move), 0);
  ok($context -> action() == qw(move));

  $context -> status([], 0);

  $context -> drop_reply(1, 0);
  $context -> drop_finish(1, 0);

  SKIP: {
    skip "new 2.6 stuff", 1
      unless Gtk2 -> CHECK_VERSION(2, 6, 0);

    like($context -> drag_drop_succeeded(), qr/^(?:1|)$/);
  }

  $context -> drop(0);
  $context -> abort(0);
}

SKIP: {
  skip 'new 2.22 stuff', 5
    unless Gtk2->CHECK_VERSION(2, 22, 0);

  my $context = Gtk2::Gdk::DragContext -> begin($window -> window(), @targets);
  ok(defined $context -> get_actions());
  ok(defined $context -> get_selected_action());
  ok(defined $context -> get_suggested_action());
  is($context -> get_source_window(), $window -> window());
  is_deeply([map { $_ -> name() } $context -> list_targets()],
            [map { $_ -> name() } @targets]);
}

__END__

Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
