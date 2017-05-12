package Gnome2::Vte;

# $Id$

use 5.008;
use strict;
use warnings;

use Gtk2;

require DynaLoader;

our @ISA = qw(DynaLoader);

our $VERSION = '0.11';

sub import {
  my $self = shift();
  $self -> VERSION(@_);
}

sub dl_load_flags { 0x01 }

Gnome2::Vte -> bootstrap($VERSION);

1;
__END__

=head1 NAME

Gnome2::Vte - Perl interface to the Virtual Terminal Emulation library

=head1 SYNOPSIS

  use strict;
  use Glib qw(TRUE FALSE);
  use Gtk2 -init;
  use Gnome2::Vte;

  # create things
  my $window = Gtk2::Window->new;
  my $scrollbar = Gtk2::VScrollbar->new;
  my $hbox = Gtk2::HBox->new;
  my $terminal = Gnome2::Vte::Terminal->new;

  # set up scrolling
  $scrollbar->set_adjustment ($terminal->get_adjustment);

  # lay 'em out
  $window->add ($hbox);
  $hbox->pack_start ($terminal, TRUE, TRUE, 0);
  $hbox->pack_start ($scrollbar, FALSE, FALSE, 0);
  $window->show_all;

  # hook 'em up
  $terminal->fork_command ('/bin/bash', ['bash', '-login'], undef,
                           '/tmp', FALSE, FALSE, FALSE);
  $terminal->signal_connect (child_exited => sub { Gtk2->main_quit });
  $window->signal_connect (delete_event =>
                           sub { Gtk2->main_quit; FALSE });

  # turn 'em loose
  Gtk2->main;

=head1 ABSTRACT

This module allows a Perl developer to use the Virtual Terminal Emulator
library (libvte for short).

=head1 SEE ALSO

L<Gnome2::Vte::index>(3pm), L<Gtk2>(3pm), L<Gtk2::api>(3pm) and
L<http://developer.gnome.org/doc/API/2.0/vte/>.

=head1 AUTHOR

Torsten Schoenfeld E<lt>kaffeetisch at gmx dot deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2003-2006 by the gtk2-perl team

=cut
