#!/usr/bin/perl -w
# vim: set ft=perl :
use strict;
use Test::More;
use Gtk2;

# $Id$

use Config;
my $have_threads = $Config{usethreads};

Gtk2::Gdk::Threads -> init()
	if $have_threads;

@ARGV = qw(--help --name bla --urgs tree);

if (Gtk2::Gdk->init_check )
{
	plan tests => 17;
}
else
{
	plan skip_all => 'Gtk2->init_check failed, probably unable to '
		. 'open DISPLAY';
}

Gtk2::Gdk::Threads -> enter();
Gtk2::Gdk::Threads -> leave();

is(Gtk2::Gdk -> init_check(), 1);
is(Gtk2::Gdk -> init(), 1);

is_deeply(\@ARGV, [qw(--help --urgs tree)]);

# Also call Gtk2's init to avoid hangs.
Gtk2 -> init();

SKIP: {
  skip("parse_args, get_display_arg_name and notify_startup_complete are new in 2.2", 1)
    unless Gtk2 -> CHECK_VERSION(2, 2, 0);

  @ARGV = qw(--help --name bla --urgs tree);

  # FIXME: this immediately returns if gdk is already initialized.  so does
  # gdk_init.  how to test both of them in one test?
  Gtk2::Gdk -> parse_args();

  is_deeply(\@ARGV, [qw(--help --name bla --urgs tree)]);

  Gtk2::Gdk -> get_display_arg_name(); # FIXME: check retval?
  Gtk2::Gdk -> notify_startup_complete();
}

SKIP: {
  skip 'new 2.12 stuff', 0
    unless Gtk2 -> CHECK_VERSION(2, 12, 0);

  Gtk2::Gdk -> notify_startup_complete_with_id('bla');
}

ok(Gtk2::Gdk -> set_locale());
Gtk2::Gdk -> set_sm_client_id("blub");
Gtk2::Gdk -> set_sm_client_id(undef);

Gtk2::Gdk -> set_program_class("gtk2perl");
is(Gtk2::Gdk -> get_program_class(), "gtk2perl");

ok(Gtk2::Gdk -> get_display());
Gtk2::Gdk -> flush();

my $number = qr/^\d+$/;
like(Gtk2::Gdk -> screen_width(), $number);
like(Gtk2::Gdk -> screen_height(), $number);
like(Gtk2::Gdk -> screen_width_mm(), $number);
like(Gtk2::Gdk -> screen_height_mm(), $number);

my $window = Gtk2::Window -> new();
$window -> show_all();
$window -> show_now();

my $result = Gtk2::Gdk -> pointer_grab($window -> window(),
                                       1,
                                       qw(button-press-mask),
                                       undef,
                                       Gtk2::Gdk::Cursor -> new("arrow"),
                                       0);

like($result, qr/^(?:success|already-grabbed|not-viewable)$/);
like(Gtk2::Gdk -> pointer_is_grabbed(), qr/^(?:1|)$/);

Gtk2::Gdk -> pointer_ungrab(0);

# Gtk2::Gdk -> set_double_click_time(20);

$result = Gtk2::Gdk -> keyboard_grab($window -> window(), 1, 0);
like($result, qr/^(?:success|already-grabbed|not-viewable)$/);
Gtk2::Gdk -> keyboard_ungrab(0);

Gtk2::Gdk -> error_trap_push();
is(Gtk2::Gdk -> error_trap_pop(), 0);

my $event = Gtk2::Gdk::Event -> new("client-event");

$event -> window($window -> window());
$event -> message_type(Gtk2::Gdk::Atom -> new("string"));
$event -> data_format(Gtk2::Gdk::CHARS);
$event -> data("01234567890123456789");

SKIP: {
  skip("X11 stuff", 2)
    unless $window -> window() -> can("get_xid");

  is(Gtk2::Gdk::Event -> send_client_message(
       $event, $window -> window() -> get_xid()),
     1);
  Gtk2::Gdk::Event -> send_clientmessage_toall($event);

  skip("GdkDisplay is new in 2.2", 1)
    unless Gtk2 -> CHECK_VERSION(2, 2, 0);

  is(Gtk2::Gdk::Event -> send_client_message_for_display(
       Gtk2::Gdk::Display -> get_default(), $event,
       $window -> window() -> get_xid()),
     1);
}

# Gtk2::Gdk -> beep();

__END__

Copyright (C) 2003-2006 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
