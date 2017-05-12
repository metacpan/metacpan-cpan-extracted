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
   'ok',
   "Hello world!"
);

$dialog->signal_connect( response => sub {
   $loop->loop_stop;
} );

$dialog->show_all;

$loop->loop_forever;
