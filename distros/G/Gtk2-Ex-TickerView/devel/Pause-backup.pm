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

package Gtk2::Ex::TickerView::Pause;
use strict;
use warnings;
use 5.008;

our $VERSION = 15;

sub new {
  my ($class, $tickerview) = @_;
  my $self = { tickerview => $tickerview,
               not_paused => 1
             }, $class;
  Scalar::Util::weaken ($self->{'tickerview'});
  $self->pause;
  return $self;
}

sub DESTROY {
  my ($self) = @_;
  $self->unpause;
}

sub pause {
  my ($self) = @_;
  my $tickerview = $self->{'tickerview'} || return;
  delete $self->{'not_paused'} or return;
  $tickerview->{'paused_count'} ++;
  Gtk2::Ex::TickerView::_update_timer ($self);  
}

sub unpause {
  my ($self) = @_;
  my $tickerview = $self->{'tickerview'} || return;
  return if $self->{'not_paused'};
  $self->{'not_paused'} = 1;
  $tickerview->{'paused_count'} --;
  Gtk2::Ex::TickerView::_update_timer ($self);  
}

1;
__END__

=head1 NAME

Gtk2::Ex::TickerView::Pause -- temporarily stop scrolling in a TickerView

=head1 SYNOPSIS

 use Gtk2::Ex::TickerView::Pause;
 my $pobj = Gtk2::Ex::TickerView::Pause->new ($tickerview);
 ...
 $pobj = undef; # scroll resumes when object destroyed

=head1 DESCRIPTION

A C<Gtk2::Ex::TickerView::Pause> object suppresses the timer scrolling in a
given C<Gtk2::Ex::TickerView> widget.  When all Pause objects on that widget
are destroyed it resumes normal operation.

This kind of pause is used by the builtin mouse drag feature and is offered
for other similar uses.  For example you might want to pause during a popup
menu if it relates to an item current showing.

The C<run> property in the TickerView is a separate setting.  Usually it's
the one you want for an overall user stop/go control.  A Pause is intended
as a temporary stop for some reason, without losing the overall C<run>
setting.

For reference, a TickerView scrolls when

    - run property is true
    - speed property is non-zero
    - frame-rate property is non-zero
    - there's no button drag in progress
    - there's no user Pause objects

Internally, to save some work, the scroll timer also stops when there's
nothing to see, which means no renderers, or no model, or the model is
empty, or the widget is not mapped, or it's fully obscured by other windows.
(Unmapped or an empty model are the most likely.  Fully obscured can occur
fairly easily.)

=head1 FUNCTIONS

=over 4

=item C<< $pause = Gtk2::Ex::TickerView::Pause->new ($tickerview) >>

Create and return a new C<Gtk2::Ex::TickerView::Pause> object which stops
the timer scrolling in C<$tickerview>.  When you discard the object it
releases the pause, allowing scrolling to resume (once there's no other
Pauses, and the ticker C<run> is active, etc).

The Pause object only keeps a weak reference to C<$tickerview>, so the mere
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
