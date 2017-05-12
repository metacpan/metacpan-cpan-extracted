# Copyright 2008, 2009, 2010, 2011, 2012 Kevin Ryde

# This file is part of Gtk2-Ex-WidgetBits.
#
# Gtk2-Ex-WidgetBits is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-WidgetBits is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-WidgetBits.  If not, see <http://www.gnu.org/licenses/>.


package Test::Weaken::Gtk2;
use 5.006;  # for "our" (which Test::Weaken itself uses)
use strict;
use warnings;
use Scalar::Util 'refaddr';

# uncomment this to run the ### lines
#use Smart::Comments;

use Exporter;
our @ISA = ('Exporter');
our @EXPORT_OK = qw(contents_container
                    contents_submenu
                    contents_cell_renderers
                    destructor_destroy
                    destructor_destroy_and_iterate
                    ignore_default_display);

our $VERSION = 48;

sub contents_container {
  my ($ref) = @_;
  require Scalar::Util;
  if (Scalar::Util::blessed($ref)
      && $ref->isa('Gtk2::Container')) {
    return $ref->get_children;
  } else {
    return ();
  }
}

sub contents_submenu {
  my ($ref) = @_;
  require Scalar::Util;
  if (Scalar::Util::blessed($ref)) {
    my $menu;
    if ($ref->isa('Gtk2::MenuItem')) {
      $menu = $ref->get_submenu;
    } elsif ($ref->isa('Gtk2::MenuToolButton')) {
      $menu = $ref->get_menu;
    }
    if (defined $menu) {
      return $menu;
    }
  }
  return ();
}

sub contents_cell_renderers {
  my ($ref) = @_;

  require Scalar::Util;
  Scalar::Util::blessed($ref) || return;
  my $method;
  if ($ref->isa('Gtk2::CellLayout')
      && $ref->can('get_cells')) {  # new in Gtk 2.12
    $method = 'get_cells';

  } elsif ($ref->isa('Gtk2::TreeViewColumn') || $ref->isa('Gtk2::CellView')) {
    # gtk_cell_view_get_cell_renderers() or
    # gtk_tree_view_column_get_cell_renderers() pre-dating the interface
    # style
    $method = 'get_cell_renderers';

  } else {
    return;
  }

  # as of Gtk 2.20.1 GtkCellView tries to set the data into the cells
  # returned by either the get_cells interface or
  # gtk_cell_view_get_cell_renderers().  If there's no display_row set then
  # it throws a g_log.  Suppress that in case we're looking for leaks in an
  # empty CellView or without a display_row.
  #
  my @cells;
  {
    my $old_warn = $SIG{__WARN__};
    local $SIG{__WARN__} = sub {
      my ($str) = @_;
      if (index ($str, 'Gtk-CRITICAL **: gtk_cell_view_set_cell_data: assertion') >= 0) {
        ### Suppressed gtk_cell_view_set_cell_data() assertion failure
        return;
      }
      if ($old_warn) {
        $old_warn->(@_);
      } else {
        warn @_;
      }
    };
    @cells = $ref->$method;
  }

  # Gtk2-Perl 1.221 returns a one-element list of undef if no cells.
  # Prefer to return an empty list for that case.
  if (@cells == 1 && ! defined $cells[0]) {
    @cells = ();
  }
  return @cells;
}

#------------------------------------------------------------------------------
sub destructor_destroy {
  my ($ref) = @_;
  if (ref($ref) eq 'ARRAY') {
    $ref = $ref->[0];
  }
  $ref->destroy;
}

sub destructor_destroy_and_iterate {
  my ($ref) = @_;
  destructor_destroy ($ref);
  _main_iterations();
}

# Gtk 2.16 can go into a hard loop on events_pending() / main_iteration_do()
# if dbus is not running, or something like that.  In any case limiting the
# iterations is good for test safety.
#
# FIXME: Not sure how aggressive to be on hitting the maximum count.  If
# testing can likely continue then a diagnostic is enough, but maybe a
# count-out means something too broken to continue.
#
# The iterations count actually run is cute to see to check what has gone
# through the main loop.  Would it be worth giving that always, or under an
# option, or something?
#
sub _main_iterations {
  require Test::More;
  my $count = 0;
  ### _main_iterations() ...
  while (Gtk2->events_pending) {
    $count++;
    Gtk2->main_iteration_do (0);

    if ($count >= 1000) {
      ### _main_iterations() count exceeded: $count
      eval {
        Test::More::diag ("main_iterations(): oops, bailed out after $count events/iterations");
      };
      return;
    }
  }
  ### _main_iterations() events/iterations: $count
}

#------------------------------------------------------------------------------
sub ignore_default_display {
  my ($ref) = @_;

  # Gtk2 loaded, and Gtk 2.2 up
  Gtk2::Gdk::Display->can('get_default') || return 0;

  my $default_display = Gtk2::Gdk::Display->get_default
    || return 0;  # undef until Gtk2 inited

  return (refaddr($ref) == refaddr($default_display));
}

sub ignore_default_screen {
  my ($ref) = @_;

 # Gtk2 loaded, and Gtk 2.2 up
  Gtk2::Gdk::Screen->can('get_default') || return 0;

  my $default_screen = Gtk2::Gdk::Screen->get_default
    || return 0;  # undef until Gtk2 inited

  return (refaddr($ref) == refaddr($default_screen));
}

sub ignore_default_root_window {
  my ($ref) = @_;

  # must have Gtk2 loaded
  Gtk2::Gdk->can('get_default_root_window') or return 0;

  # in Gtk 2.2 up must have default screen from Gtk2->init_check() otherwise
  # Gtk2::Gdk->get_default_root_window() gives a g_log() warning
  if (Gtk2::Gdk::Screen->can('get_default')) {
    Gtk2::Gdk::Screen->get_default || return 0;
  }

  # in Gtk 2.0 get NULL from gdk_get_default_root_window() if no
  # Gtk2->init_check() yet
  my $default_root_window = Gtk2::Gdk->get_default_root_window
    || return 0;

  return (refaddr($ref) == refaddr($default_root_window));
}


#------------------------------------------------------------------------------
1;
__END__

=for stopwords destructors arrayref submenu MenuItem Destructor toplevel AccelLabel finalizations Ryde Gtk2-Ex-WidgetBits Gtk Gtk2 MenuToolButton renderers CellViews

=head1 NAME

Test::Weaken::Gtk2 -- Gtk2 helpers for Test::Weaken

=head1 SYNOPSIS

 use Test::Weaken::Gtk2;

=head1 DESCRIPTION

This is a few functions to help C<Test::Weaken> leak checking on C<Gtk2>
widgets etc.  The functions can be used individually, or combined into
larger application-specific contents etc handlers.

This module doesn't load C<Gtk2>.  If C<Gtk2> is not loaded then the
functions simply return empty, false, or do nothing, as appropriate.  This
module also doesn't load C<Test::Weaken>, that's left to a test script.

=head1 FUNCTIONS

=head2 Contents Functions

=over 4

=item C<< @widgets = Test::Weaken::Gtk2::contents_container ($ref) >>

If C<$ref> is a C<Gtk2::Container> or subclass then return its widget
children per C<< $container->get_children() >>.  If C<$ref> is not a
container, or C<Gtk2> is not loaded, then return an empty list.

Container children are held in C structures (unless the container is
implemented in Perl) and so generally not reached by the traversal
C<Test::Weaken> does.

=item C<< @widgets = Test::Weaken::Gtk2::contents_submenu ($ref) >>

If C<$ref> is a C<Gtk2::MenuItem> then return its submenu per
C<< $item->get_submenu() >>, or if it's a C<Gtk2::MenuToolButton> then per
C<< $item->get_menu() >>.  If there's no menu, or C<$ref> is not such a
widget, then return an empty list.

The submenu in both cases is held in the item's C structure and is not
otherwise reached by the traversal C<Test::Weaken> does.

Only the MenuItem and MenuToolButton classes are acted on currently, just in
case a C<get_submenu()> / C<get_menu()> on some other Gtk class isn't a simple
property fetch but perhaps some kind of constructor.  Other classes which
are a simple fetch could be added here in the future.

=item C<< @widgets = Test::Weaken::Gtk2::contents_cell_renderers ($ref) >>

If C<$ref> is a widget with the C<Gtk2::CellLayout> interface then return
its C<Gtk2::CellRenderer> objects from C<get_cells()>.  Or if C<$ref> is a
C<Gtk2::TreeViewColumn> or C<Gtk2::CellView> then C<get_cell_renderers()>.
For anything else the return is an empty list.

C<get_cells> is new in Gtk 2.12.  C<get_cell_renderers()> is the previous
style.  The renderers in a C code viewer widget are held in C structures and
are not otherwise reached by the traversal C<Test::Weaken> does.

C<Gtk2::CellView> as of Gtk 2.20.1 has a bug or severe misfeature where it
gives a C<g_assert()> failure on attempting get cells when there's no
display row set, including when no model.  The returned cells are correct,
there's just an assert logged.  C<contents_cell_renderers()> suppresses that
warning so as to help leak checking of CellViews not yet displaying
anything.

=back

When a C-code widget has sub-widgets or renderers as part of its
implementation, those children will end up extracted and leak checked by the
functions above.  This is usually desirable in as much as it notices leaks,
even though they may not relate to Perl level code.

=head2 Destructor Functions

=over 4

=item C<< Test::Weaken::Gtk2::destructor_destroy ($top) >>

Call C<< $top->destroy() >>, or if C<$top> is an arrayref then call
C<destroy()> on its first element.  This can be used when a constructed
widget or object requires an explicit C<destroy()>.  For example,

    my $leaks = leaks({
      constructor => sub { Gtk2::Window->new('toplevel') },
      destructor => \&Test::Weaken::Gtk2::destructor_destroy,
    });

The arrayref case is designed for multiple widgets etc returned from a
constructor, the first of which is a toplevel window or similar needing a
C<destroy()>,

    my $leaks = leaks({
      constructor => sub {
        my $toplevel = Gtk2::Window->new('toplevel');
        my $label = Gtk2::Label->new('Hello World');
        $toplevel->add($label);
        return [ $toplevel, $label ];
      },
      destructor => \&Test::Weaken::Gtk2::destructor_destroy,
    });

All C<Gtk2::Object>s support C<destroy()> but most don't need it for garbage
collection.  C<Gtk2::Window> is the most common which does.  Another is a
MenuItem which has an AccelLabel and is not in a menu (see notes in
L<Gtk2::MenuItem>).

=item C<< Test::Weaken::Gtk2::destructor_destroy_and_iterate ($top) >>

The same as C<destructor_destroy()> above, but in addition run
C<< Gtk2->main_iteration_do() >> for queued main loop actions.  There's a
limit on the number of iterations done, so as to protect against a runaway
main loop.

This is good if some finalizations are only done in an idle handler, or
perhaps under a timer which has now expired.  Currently queued events from
the X server are run, but there's no read or wait for further events.

=back

=head2 Ignore Functions

=over 4

=item C<< $bool = Test::Weaken::Gtk2::ignore_default_display ($ref) >>

=item C<< $bool = Test::Weaken::Gtk2::ignore_default_screen ($ref) >>

=item C<< $bool = Test::Weaken::Gtk2::ignore_default_root_window ($ref) >>

Return true if C<$ref> is respectively the default display, screen or root
window, as per

    Gtk2::Gdk::Display->get_default
    Gtk2::Gdk::Screen->get_default
    Gtk2::Gdk->get_default_root_window

If there's no respective default then return false.  This happens if C<Gtk2>
is not loaded yet, or C<< Gtk2->init() >> not called yet, and under Gtk
2.0.x there's no C<Gtk2::Gdk::Display> class and
C<Gtk2::Gdk::Screen> classes at all (only a default root window).

    my $leaks = leaks({
      constructor => sub { make_something },
      ignore => \&Test::Weaken::Gtk2::ignore_default_display,
    });

These default objects are generally permanent, existing across a test, and
on that basis will not normally be tracked for leaking.  Usually they're not
seen by C<leaks()> anyway, since they're only in the C structures of
widgets, windows, etc.  These ignores can be used if operating on the root
window, or holding a display or screen in Perl code.

=back

=head1 EXPORTS

Nothing is exported by default, but the functions can be requested in usual
C<Exporter> style.

    use Test::Weaken::Gtk2 'contents_container';

There's no C<:all> tag since new functions are likely to be added in the
future and an import of all would risk name clashes with application
functions etc.

=head1 SEE ALSO

L<Test::Weaken>, L<Gtk2::Container>, L<Gtk2::MenuItem>, L<Gtk2::Object>,
L<Gtk2::Window>, L<Gtk2::Gdk::Display>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/gtk2-ex-widgetbits/index.html>

=head1 LICENSE

Copyright 2008, 2009, 2010, 2011, 2012 Kevin Ryde

Gtk2-Ex-WidgetBits is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

Gtk2-Ex-WidgetBits is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Gtk2-Ex-WidgetBits.  If not, see L<http://www.gnu.org/licenses/>.

=cut
