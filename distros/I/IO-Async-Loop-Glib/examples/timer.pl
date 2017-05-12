#!/usr/bin/perl

use strict;
use warnings;

use IO::Async::Loop::Glib;
use IO::Async::Timer::Periodic;

use Gtk2 -init;

my $loop = IO::Async::Loop::Glib->new;

my $dialog = Gtk2::MessageDialog->new( undef,
   'destroy-with-parent',
   'info',
   'none',
   "Hello world!"
);

$dialog->get_content_area->add( my $message = Gtk2::Label->new );

$loop->add( my $timer = IO::Async::Timer::Periodic->new(
   interval => 1,
   on_tick  => sub { $message->set_text( "Time is now " . scalar localtime ) },
) );

$dialog->add_button( "Start", 1 )->signal_connect(
   clicked => sub {
      $timer->start;
   }
);

$dialog->add_button( "Stop", 2 )->signal_connect(
   clicked => sub {
      $timer->stop;
      $message->set_text( "" );
   }
);

$dialog->add_button( "Quit", 'close' )->signal_connect(
   clicked => sub { $loop->loop_stop }
);

$dialog->show_all;

$loop->loop_forever;
