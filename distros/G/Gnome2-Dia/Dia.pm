package Gnome2::Dia;

# $Id$

use 5.008;
use strict;
use warnings;

use Glib;
use Gtk2;
use Gnome2::Canvas;
use Gnome2::Print;

require DynaLoader;

our @ISA = qw(DynaLoader);

our $VERSION = '0.06';

sub import {
  my $self = shift();
  $self -> VERSION(@_);
}

sub dl_load_flags { $^O eq 'darwin' ? 0x00 : 0x01 }

Gnome2::Dia -> bootstrap($VERSION);

1;
__END__

=head1 NAME

Gnome2::Dia - (DEPRECATED) Perl interface to the DiaCanvas2 library

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

B<DEPRECATED> This module allows a Perl developer to use the DiaCanvas2
library.

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

Perl URL: https://gitlab.gnome.org/GNOME/perl-gnome2-dia

=item *

Upstream URL: https://sourceforge.net/projects/diacanvas/

=item *

Last upstream version: 0.15.4 (DiaCanvas2)

=item *

Last upstream release date: 2007-08-03

=item *

Migration path for this module: No upstream replacement

=back

B<NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE>


=head1 SEE ALSO

L<Gnome2::Dia::index>(3pm), L<Gtk2>(3pm), L<Gtk2::api>(3pm) and
L<http://diacanvas.sourceforge.net/ref/>.

=head1 AUTHOR

Torsten Schoenfeld E<lt>kaffeetisch@web.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by the gtk2-perl team

=cut
