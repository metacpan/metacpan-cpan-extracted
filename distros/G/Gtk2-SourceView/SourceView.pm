#
# Copyright (c) 2004-2005 by Emmanuele Bassi (see the file AUTHORS)
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Library General Public
# License as published by the Free Software Foundation; either
# version 2 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Library General Public License for more details.
#
# You should have received a copy of the GNU Library General Public
# License along with this library; if not, write to the 
# Free Software Foundation, Inc., 59 Temple Place - Suite 330, 
# Boston, MA  02111-1307  USA.

package Gtk2::SourceView;

use 5.008;
use strict;
use warnings;

use Gtk2;
use Gnome2::Print;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Gtk2::SourceView ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '1.000';

sub dl_load_flags { 0x01 }

require XSLoader;
XSLoader::load('Gtk2::SourceView', $VERSION);

# Preloaded methods go here.

1;
__END__

=head1 NAME

Gtk2::SourceView - Perl wrappers for the GtkSourceView widget

=head1 SYNOPSIS
  
  use Gtk2 '-init';
  use Gtk2::SourceView;
  
  $lm = Gtk2::SourceView::LanguagesManager->new;
  $lang = $lm->get_language_from_mime_type("application/x-perl");
  if ($lang)
  {
  	$sb = Gtk2::SourceView::Buffer->new_with_language($lang);
	$sb->set_highlight(1);
  }
  else
  {
    $sb = Gtk2::SourceView::Buffer->new(undef);
	$sb->set_highlight(0);
  }
  
  # loading a file should be atomically undoable.
  $sb->begin_not_undoable_action();
  open INFILE, "program.pl" or die "Unable to open program.pl";
  while (<INFILE>)
  {
    $sb->insert($sb->get_end_iter(), $_);
  }
  $sb->end_not_undoable_action();

  # Gtk2::SourceView::Buffer inherits from Gtk2::TextBuffer.
  $sb->set_modified(0);
  $sb->place_cursor($sb->get_start_iter());
  
  $win = Gtk2::Window->new('toplevel');
  $sw = Gtk2::ScrolledWindow->new;
  $sw->set_policy('automatic', 'automatic');
  $win->add($sw);
  
  # Gtk2::SourceView::View inherits from Gtk2::TextView.
  $view = Gtk2::SourceView::View->new_with_buffer($sb);
  $sw->add($view);
  $view->show;
  $win->show_all;

  Gtk2->main;

  0;

=head1 ABSTRACT

Perl bindings to the 1.x series of the GtkSourceView widget libraries.

=head1 DESCRIPTION

Perl bindings to the 1.x series of the GtkSourceView widget libraries.  This
module allows you to write Perl applications that utilize the GtkSourceView
library for source editing and printing.

To discuss gtk2-perl, ask questions and flame/praise the authors,
join gtk-perl-list@gnome.org at lists.gnome.org.

=head1 SEE ALSO

perl(1), Glib(3pm), Gtk2(3pm), Gnome2::Print(3pm).

=head1 AUTHORS

Emmanuele Bassi E<lt>emmanuele.bassi@iol.itE<gt>
muppet E<lt>scott at asofyet dot orgE<gt>
Torsten Schoenfeld E<lt>kaffeetisch at gmx dot deE<gt>

gtk2-perl created by the gtk2-perl team: http://gtk2-perl.sf.net

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2005 by Emmanuele Bassi (see the file AUTHORS)

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Library General Public
License as published by the Free Software Foundation; either
version 2 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Library General Public License for more details.

You should have received a copy of the GNU Library General Public
License along with this library; if not, write to the 
Free Software Foundation, Inc., 59 Temple Place - Suite 330, 
Boston, MA  02111-1307  USA.

=cut
