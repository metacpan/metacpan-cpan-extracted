package Gnome2::Vte;

# $Id$

use 5.008;
use strict;
use warnings;

use Gtk2;

require DynaLoader;

our @ISA = qw(DynaLoader);

our $VERSION = '0.12';

sub import {
  my $self = shift();
  $self -> VERSION(@_);
}

sub dl_load_flags { 0x01 }

Gnome2::Vte -> bootstrap($VERSION);

1;
__END__

=head1 NAME

Gnome2::Vte - (DEPRECATED) Perl interface to the Virtual Terminal Emulation
library

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

B<DEPRECATED> This module allows a Perl developer to use the Virtual Terminal
Emulator library (libvte for short).

=head1 DESCRIPTION

B<NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE>

This module has been deprecated by the Gtk-Perl project.  This means that the
module will no longer be updated with security patches, bug fixes, or when
changes are made in the Perl ABI.  The Git repo for this module has been
archived (made read-only), it will no longer possible to submit new commits to
it.  You are more than welcome to ask about this module on the Gtk-Perl
mailing list, but our priorities going forward will be maintaining Gtk-Perl
modules that are supported and maintained upstream; this module is neither.

Since this module is licensed under the LGPL v2.1, you may also fork this
module, if you wish, but you will need to use a different name for it on CPAN,
and the Gtk-Perl team requests that you use your own resources (mailing list,
Git repos, bug trackers, etc.) to maintain your fork going forward.

=over

=item *

Perl URL: https://gitlab.gnome.org/GNOME/perl-gnome2-vfs

=item *

Upstream URL: https://gitlab.gnome.org/Archive/gnome-vfs

=item *

Last upstream version: 2.24.4

=item *

Last upstream release date: 2010-09-28

=item *

Migration path for this module: Glib::IO

=item *

Migration module URL: https://metacpan.org/pod/Glib::IO

=back

=head1 SEE ALSO

L<Gnome2::Vte::index>(3pm), L<Gtk2>(3pm), L<Gtk2::api>(3pm) and
L<http://developer.gnome.org/doc/API/2.0/vte/>.

=head1 AUTHOR

Torsten Schoenfeld E<lt>kaffeetisch at gmx dot deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2003-2006 by the gtk2-perl team

=cut
