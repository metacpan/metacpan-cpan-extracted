package Gnome2::Wnck;

# $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Gnome2-Wnck/Wnck.pm,v 1.23 2008/03/16 12:59:48 kaffeetisch Exp $

use 5.008;
use strict;
use warnings;

use Gtk2;

require DynaLoader;

our @ISA = qw(DynaLoader);

our $VERSION = '0.16';

sub import {
  my $self = shift();
  $self -> VERSION(@_);
}

sub dl_load_flags { $^O eq 'darwin' ? 0x00 : 0x01 }

Gnome2::Wnck -> bootstrap($VERSION);

1;
__END__

=head1 NAME

Gnome2::Wnck - Perl interface to the Window Navigator Construction Kit

=head1 SYNOPSIS

  use Gtk2 -init;
  use Gnome2::Wnck;

  my $screen = Gnome2::Wnck::Screen -> get_default();
  $screen -> force_update();

  my $pager = Gnome2::Wnck::Pager -> new($screen);
  my $tasklist = Gnome2::Wnck::Tasklist -> new($screen);

=head1 ABSTRACT

This module allows a Perl developer to use the Window Navigator Construction
Kit library (libwnck for short) to write tasklists and pagers.

=head1 SEE ALSO

L<Gnome2::Wnck::index>(3pm), L<Gtk2>(3pm), L<Gtk2::api>(3pm) and the source
code of libwnck.

=head1 AUTHOR

Torsten Schoenfeld E<lt>kaffeetisch@web.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2003-2006 by the gtk2-perl team

=cut
