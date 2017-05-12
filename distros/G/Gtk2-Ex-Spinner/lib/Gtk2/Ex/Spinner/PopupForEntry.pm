package Gtk2::Ex::Spinner::PopupForEntry;
use 5.008;
use strict;
use warnings;
use Gtk2;
use List::Util qw(min max);

our $VERSION = 5.1;

use constant DEBUG => 0;

use Glib::Object::Subclass
  'Gtk2::Window',
  properties => [ Glib::ParamSpec->object
                  ('entry',
                   'entry',
                   'Blurb.',
                   'Gtk2::Widget',
                   Glib::G_PARAM_READWRITE)
                ];

sub INIT_INSTANCE {
  my ($self) = @_;

  $self->set_decorated (0);
  $self->set_flags('can-focus');
  
  $self->set_keep_above(1);
  $self->set_type_hint('splashscreen');

  my $hbox = Gtk2::HBox->new;
  $self->add ($hbox);

  require Gtk2::Ex::Spinner;
  my $spinner = Gtk2::Ex::Spinner->new;
  $self->{'spinner'} = $spinner;
  $hbox->pack_start ($spinner, 1,1,0);

  
  $spinner->{'spin'}->signal_connect_after (activate => \&_do_activate);
  
  $spinner->signal_connect ('notify::value' => \&_do_spinner_changed);

  my $ok = Gtk2::Button->new_from_stock ('gtk-ok');
  $ok->set_flags('can-default');
  $ok->signal_connect (clicked => \&_do_activate);
  $hbox->pack_start ($ok, 0,0,0);

  my $cancel = Gtk2::Button->new_from_stock ('gtk-cancel');
  $cancel->signal_connect (clicked => \&_do_cancel_button);
  $hbox->pack_start ($cancel, 0,0,0);

  my $accelgroup = Gtk2::AccelGroup->new;
  $self->add_accel_group ($accelgroup);
  $accelgroup->connect (Gtk2::Gdk->keyval_from_name('Escape'), [], [],
                        \&_do_accel_cancel);

  $spinner->{'spin'}->grab_focus;
  $hbox->show_all;

}

if (DEBUG) {
  no warnings 'once';
  *FINALIZE_INSTANCE = sub {
    print "PopupForEntry FINALIZE_INSTANCE\n";
  };
}

# A 'border' decoration is probably worthwhile, but $toplevel->move doesn't
# seem to be based on window frame position in fvwm.  Dunno who's at fault,
# but no decoration is easier to get right in all wm's.
#
#  signals => { realize => \&_do_realize },
# sub _do_realize {
#   my ($self) = @_;
#   $self->signal_chain_from_overridden;
#   $self->window->set_decorations (['border']);
# }

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  $self->{$pname} = $newval;

  if ($pname eq 'entry') {
    my $entry = $newval;
    Scalar::Util::weaken ($self->{'entry'});

    $self->{'entry_ids'} = $entry && do {
      require Scalar::Util;
      my $ref_weak_self = \$self;
      Scalar::Util::weaken ($ref_weak_self);

      require Glib::Ex::SignalIds;
      Glib::Ex::SignalIds->new
          ($entry,
           $entry->signal_connect (size_allocate => \&_do_position,
                                   $ref_weak_self),
           $entry->signal_connect (changed => \&_do_entry_changed,
                                   $ref_weak_self),
           $entry->signal_connect (editing_done => \&_do_entry_editing_done,
                                   $ref_weak_self),
           $entry->signal_connect (destroy => \&_do_entry_destroy,
                                   $ref_weak_self))
        };
  }
}

sub _do_entry_destroy {
  my ($entry, $ref_weak_self) = @_;
  my $self = $$ref_weak_self || return;
  if (DEBUG) { print "PopupForEntry _do_entry_destroy, destroy $self too\n"; }
  $self->destroy;
}

sub _do_entry_changed {
  my ($entry, $ref_weak_self) = @_;
  if (DEBUG) { print "PopupForEntry _do_entry_changed\n"; }
  my $self = $$ref_weak_self || return;
  if ($self->{'change_in_progress'}) { return; }

  local $self->{'change_in_progress'} = 1;
  my $value = $entry->get_text;
  if ($value =~ /^\d+$/) {
    my $spinner = $self->{'spinner'};
    $spinner->set (value => $value);
  }
}
sub _do_spinner_changed {
  my ($spinner,  $pspec) = @_;
  my $self = $spinner->get_toplevel;
  if (DEBUG) { print "PopupForEntry _do_spinner_value to ",
                 $self->{'entry'},"\n"; }
  if ($self->{'change_in_progress'}) { return; }
  my $entry = $self->{'entry'} || return;

  local $self->{'change_in_progress'} = 1;
  $entry->set_text ($spinner->get_value);
}

sub _do_entry_editing_done {
  my ($entry, $ref_weak_self) = @_;
  my $self = $$ref_weak_self || return;
  if (DEBUG) { print "PopupForEntry: _do_entry_editing_done, hide popup\n"; }
  $self->hide;
}

# 'activate' on the spin buttons
# 'clicked' on the 'gtk-ok' button
#
sub _do_activate {
  my ($widget) = @_;
  if (DEBUG) { print "PopupForEntry _do_activate\n"; }
  my $self = $widget->get_toplevel;

  $self->hide;
  my $entry = $self->{'entry'} || return;
  { local $self->{'change_in_progress'} = 1;
    my $spinner = $self->{'spinner'};
    $entry->set_text ($spinner->get_value); }
  $entry->activate;
}

# Escape key from the Gtk2::AccelGroup
# func per GtkAccelGroupActivate
#
sub _do_accel_cancel {
  my ($accelgroup, $widget, $keyval, $modifiers) = @_;
  if (DEBUG) { print "PopupForEntry _do_accel_cancel\n"; }
  _do_cancel_button ($widget);
  return 1; # accel handled
}

# 'clicked' on the cancel buttons
#
sub _do_cancel_button {
  my ($button) = @_;
  if (DEBUG) { print "PopupForEntry _do_cancel_button\n"; }
  my $self = $button->get_toplevel;

  $self->hide;
  my $entry = $self->{'entry'} || return;  # maybe already gone
  $entry->cancel;
}

# 'size-allocate' on the entry widget
#
# Finding the right time to position the popup is a bit painful.
# GtkTreeView and GtkIconView add the editable to themselves and map it with
# default height 1, then focus to it, then size_allocate it up to the cell
# size.  So to position underneath it we only know the right height after
# that size-allocate.  Positioning earlier at the map or the focus state
# ends up with an unattractive visible move of the popup window downwards.
#
# FIXME: Depending on the sequence of actions in TreeView is a bit nasty,
# maybe it'd at least be worth a recheck of the position on getting to
# Glib::Idle after a start_editing.
#
sub _do_position {
  my ($entry) = @_;
  my $ref_weak_self = $_[-1];
  my $self = $$ref_weak_self || return;
  if (DEBUG) {
    my $hint = $entry->signal_get_invocation_hint;
    print "_do_position for ",$hint->{'signal_name'},
      "  visible=",($entry->get('visible')?"yes":"no"),
        " mapped=",($entry->mapped?"yes":"no"),
          "\n";
    if (my $win = $entry->window) {
      my ($width,$height) = $win->get_size;
      print "  window ${width}x$height\n";
    }
    my $alloc = $entry->allocation;
    print "  alloc ",$alloc->width,"x",$alloc->height,"\n";
  }

  #my $toplevel = $entry->get_ancestor ('Gtk2::Window'); # undef if no toplevel
  #$self->set_transient_for ($toplevel);

  my $win = $entry->window;
  if ($win) {
    _window_move_underneath ($self, $entry);
  }
  $self->set (visible => defined $win);
}

# _window_move_underneath ($toplevel, $widget)
# $toplevel is a Gtk2::Window widget, $widget is any realized widget.
#
# Move $toplevel with $toplevel->move to put it:
#   - underneath $widget, if it fits,
#   - otherwise above, if it fits,
#   - otherwise at the bottom of the screen, but limited to y=0 if higher
#     than the whole screen
#
# Horizontally, $toplevel is positioned lined up with the left of $widget,
# but pushed to the left so as not to extend past the right edge of the
# screen, but limited to x=0 if wider than the whole screen.
#
sub _window_move_underneath {
  my ($toplevel, $widget) = @_;
  if (DEBUG) { print "_window_move_underneath\n"; }

  require Gtk2::Ex::WidgetBits;
  my ($x, $y) = Gtk2::Ex::WidgetBits::get_root_position ($widget);
  my $alloc = $widget->allocation;
  my $width = $alloc->width;
  my $height = $alloc->height;

  my $req; # either Gtk2::Gdk::Rectangle or Gtk2::Requisition
  if (my $win = $toplevel->window) {
    $req = $win->get_frame_extents;
    if (DEBUG) { print "  using get_frame_extents ",
                   $req->x,",",$req->y," ",$req->width,"x",$req->height,"\n";
                 my ($w,$h) = $win->get_size;
                 print "  cf get_size ${w}x${h}\n";
                 my $al = $toplevel->allocation;
                 print "  cf allocation ",$al->width,"x",$al->height,"\n";
               }
  } else {
    if (DEBUG) { print "  unrealized, using size_request\n"; }
    $req = $toplevel->size_request;
  }

  my $rootwin = $toplevel->get_root_window;
  my ($root_width, $root_height) = $rootwin->get_size;
  if (DEBUG) { print "  toplevel ",$req->width,"x",$req->height,"\n";
               print "  under rect $x,$y ${width}x${height}";
             }

  my $win_x = max (0, min ($root_width - $req->width, $x, ));

  my $win_y = $y + $height;
  if ($win_y + $req->height > $root_height) {
    # below is past bottom of screen, try above
    $win_y = $y - $req->height;
    if ($win_y < 0) {
      # above is past top of screen, clamp to top
      $win_y = 0;
    }
  }

  # 'gravity' (GdkGravity) doesn't really help to position above a selected
  # position for a one-off move, it only works if set and left.  Could be ok
  # since this popup is supposed to be private, but a bit easier to stay
  # default north-west for now.
  #
  $toplevel->move ($win_x, $win_y);
}

1;

__END__

=head1 NAME

Gtk2::Ex::Spinner::PopupForEntry -- popup Spinner for a Gtk2::Entry

=head1 SYNOPSIS

 use Gtk2::Ex::Spinner::PopupForEntry;
 my $entry = Gtk2::Ex::Spinner::PopupForEntry->new;

=head1 WIDGET HIERARCHY

C<Gtk2::Ex::Spinner::PopupForEntry> is a subclass of C<Gtk2::Window>.

    Gtk2::Widget
      Gtk2::Container
        Gtk2::Bin
          Gtk2::Window
            Gtk2::Ex::Spinner::PopupForEntry

=head1 DESCRIPTION

C<Gtk2::Ex::Spinner::PopupForEntry> is based on a great 
L<Gtk2::Ex::DateSpinner::PopupForEntry>, so in most cases documentation 
is the same. License is (of course) the same too :-).

B<Caution: This is internals of C<Gtk2::Ex::Spinner::CellRenderer>.  The
idea of a popup under an edited cell might be split out under a new name at
some time though, or even the idea of a DateSpinner popup standing alone.>

C<Spinner::PopupForEntry> holds a C<Gtk2::Ex::Spinner> and Ok and
Cancel buttons.  It positions itself under a given C<Gtk2::Entry> (or
subclass of C<Gtk2::Entry>) and communicates its value back and forward with
that Entry for dual editing.  Only a weak reference is held on the Entry and
when the entry is destroyed the PopupForEntry is closed and destroyed too.

=head1 PROPERTIES

=over 4

=item C<entry> (C<Gtk2::Entry> widget, held as weak ref)

=back

=head1 SEE ALSO

L<Gtk2::Ex::DateSpinner::CellRenderer>, L<Gtk2::Window>

=head1 LICENSE

Gtk2-Ex-Spinner is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

Gtk2-Ex-Spinner is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Gtk2-Ex-Spinner.  If not, see L<http://www.gnu.org/licenses/>.

=cut
