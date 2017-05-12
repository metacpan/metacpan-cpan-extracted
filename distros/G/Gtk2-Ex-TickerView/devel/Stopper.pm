# Gtk2::Ex::TickerView::Stopper
#     tickerview
#     active
#
# Gtk2::Ex::TickerView::Stopper->for_menu($tickerview, $menu)
# $ticker->stop_for_menu
#     while menu popped up
# Gtk2::Ex::TickerView::StopForMenu
#     tickerview  - weak
#     menu        - weak
#     active





# Copyright 2008, 2009, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-TickerView.
#
# Gtk2-Ex-TickerView is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-TickerView is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-TickerView.  If not, see <http://www.gnu.org/licenses/>.

package Gtk2::Ex::TickerView::Stopper;
use strict;
use warnings;
use 5.008;
use Scalar::Util 'weaken';
use Gtk2::Ex::TickerView;

our $VERSION = 15;

my $pspec_stop;
BEGIN {
  $pspec_stop = Glib::ParamSpec->boolean
    ('stop',
     'stop',
     'Whether to stop the ticker.',
     1, # default yes
     Glib::G_PARAM_READWRITE);
}

use Glib::Object::Subclass
  'Glib::Object',
  properties => [ Glib::ParamSpec->object
                  ('tickerview',
                   'tickerview',
                   'TickerView widget to operate on.',
                   'Gtk2::Ex::TickerView',
                   Glib::G_PARAM_READWRITE),

                  $pspec_stop,
                ];

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  my $oldval = $self->{$pname};
  $self->{$pname} = $newval;

  if ($pname eq 'tickerview') {
    if ($oldval) {
      delete $oldval->{'stoppers'}->{$self+0};
      $oldval->_update_timer;
    }
    if ($newval) {
      weaken ($self->{'tickerview'});
    }
  }

  if (my $tickerview = $self->{'tickerview'}) {
    weaken ($tickerview->{'stoppers'}->{$self+0} = $self);
    #     if ($self->{'stop'}) {
    #     } else {
    #       delete $tickerview->{'stoppers'}->{$self+0};
    #     }
    $tickerview->_update_timer;
  }
}

sub FINALIZE_INSTANCE {
  my ($self) = @_;
  SET_PROPERTY ($self, $pspec_stop, 0);
}

# sub stop {
#   my ($self) = @_;
#   $self->set (stop => 1);
# }
# 
# sub unstop {
#   my ($self) = @_;
#   $self->set (stop => 0);
# }

1;
__END__

=head1 NAME

Gtk2::Ex::TickerView::Stopper -- stop scrolling in a TickerView

=head1 SYNOPSIS

 use Gtk2::Ex::TickerView::Stopper;
 my $stopper = Gtk2::Ex::TickerView::Stopper->new
                 (tickerview => $tickerview);

=head1 DESCRIPTION

A C<Gtk2::Ex::TickerView::Stopper> object suppresses the timer scrolling in a
given C<Gtk2::Ex::TickerView> widget.  When all Stopper objects on that widget
are destroyed it resumes normal operation.

This kind of pause is used by the builtin mouse drag feature and is offered
for other similar uses.  For example you might want to pause during a popup
menu if it relates to an item current showing.

The C<run> property in the TickerView is a separate setting.  Usually it's
the one you want for an overall user stop/go control.  A Stopper is intended
as a temporary stop for some reason, without losing the overall C<run>
setting.

For reference, a TickerView scrolls when

    - run property is true
    - speed property is non-zero
    - frame-rate property is non-zero
    - there's no button drag in progress
    - there's no user Stopper objects

Internally, to save some work, the scroll timer also stops when there's
nothing to see, which means no renderers, or no model, or the model is
empty, or the widget is not mapped, or it's fully obscured by other windows.
(Unmapped or an empty model are the most likely.  Fully obscured can occur
fairly easily.)

=head1 FUNCTIONS

=over 4

=item C<< $pause = Gtk2::Ex::TickerView::Stopper->new ($tickerview) >>

Create and return a new C<Gtk2::Ex::TickerView::Stopper> object which stops
the timer scrolling in C<$tickerview>.  When you discard the object it
releases the pause, allowing scrolling to resume (once there's no other
Stoppers, and the ticker C<run> is active, etc).

The Stopper object only keeps a weak reference to C<$tickerview>, so the mere
fact you want to pause it doesn't keep it alive.  This also means it's safe
to hold a pause object somewhere within C<$tickerview> itself without
creating a circular reference.

=back

=head1 SEE ALSO

L<Gtk2::Ex::TickerView>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/gtk2-ex-tickerview/index.html>

=head1 COPYRIGHT

Copyright 2008, 2009, 2010 Kevin Ryde

Gtk2-Ex-TickerView is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

Gtk2-Ex-TickerView is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Gtk2-Ex-TickerView.  If not, see L<http://www.gnu.org/licenses/>.

=cut
