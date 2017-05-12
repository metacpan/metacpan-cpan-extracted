package Gnome2::Dia;

# $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Gnome2-Dia/Dia.pm,v 1.4 2005/02/24 17:40:26 kaffeetisch Exp $

use 5.008;
use strict;
use warnings;

use Glib;
use Gtk2;
use Gnome2::Canvas;
use Gnome2::Print;

require DynaLoader;

our @ISA = qw(DynaLoader);

our $VERSION = '0.04';

sub import {
  my $self = shift();
  $self -> VERSION(@_);
}

sub dl_load_flags { $^O eq 'darwin' ? 0x00 : 0x01 }

Gnome2::Dia -> bootstrap($VERSION);

1;
__END__

=head1 NAME

Gnome2::Dia - Perl interface to the DiaCanvas2 library

=head1 SYNOPSIS

  use strict;
  use warnings;

  use Glib qw(TRUE FALSE);
  use Gtk2 -init;
  use Gnome2::Dia;

  my $window = Gtk2::Window -> new();
  my $canvas = Gnome2::Dia::Canvas -> new();
  my $view = Gnome2::Dia::CanvasView -> new($canvas, TRUE);

  my $box = Gnome2::Dia::CanvasItem -> create("Gnome2::Dia::CanvasBox",
                                              border_width => 1.5);
  $canvas -> root -> add($box);
  $box -> move(100, 100);

  $window -> add($view);
  $window -> set_default_size(600, 400);
  $window -> set_title("Sample");
  $window -> show_all();

  $window -> signal_connect(delete_event => sub {
    Gtk2 -> main_quit();
    return FALSE;
  });

  Gtk2 -> main();

=head1 ABSTRACT

This module allows a Perl developer to use the DiaCanvas2 library.

=head1 SEE ALSO

L<Gnome2::Dia::index>(3pm), L<Gtk2>(3pm), L<Gtk2::api>(3pm) and
L<http://diacanvas.sourceforge.net/ref/>.

=head1 AUTHOR

Torsten Schoenfeld E<lt>kaffeetisch@web.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by the gtk2-perl team

=cut
