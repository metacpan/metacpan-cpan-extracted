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

package Gtk2::Ex::Statusbar::MessageUntilKey;
use 5.008;
use strict;
use warnings;
use Gtk2;

# WidgetBits 11 through 15 mistakenly had only $VERSION==1 here
our $VERSION = 48;

sub message {
  my ($class, $statusbar, $str) = @_;
  $statusbar->{(__PACKAGE__)} ||= $class->_new($statusbar);
  my $id = $statusbar->get_context_id(__PACKAGE__);
  $statusbar->pop ($id);
  $statusbar->push ($id, $str);
}

# The alternative would be a single KeySnooper object and emission hook, and
# have it look through a list of statusbars with messages, maybe held in a
# Tie::RefHash::Weak.  But normally there'll be just one or two statusbars,
# so aim for small and simple.
#
sub _new {
  my ($class, $statusbar) = @_;

  require Scalar::Util;
  require Gtk2::Ex::KeySnooper;
  Scalar::Util::weaken (my $weak_statusbar = $statusbar);
  return bless
    { snooper => Gtk2::Ex::KeySnooper->new (\&_do_event, \$weak_statusbar),
      emission_id => Gtk2::Widget->signal_add_emission_hook
      (button_press_event => \&_do_button_hook, \$weak_statusbar)
    }, $class;
}

sub DESTROY {
  my ($self) = @_;
  Gtk2::Widget->signal_remove_emission_hook
      (button_press_event => $self->{'emission_id'});
}

sub remove {
  my ($class_or_self, $statusbar) = @_;
  ### MessageUntilKey remove: $statusbar->{(__PACKAGE__)}

  delete $statusbar->{(__PACKAGE__)} || return;
  my $id = $statusbar->get_context_id(__PACKAGE__);
  $statusbar->pop ($id);
}

# KeySnooper handler, and called from button below
sub _do_event {
  my ($widget, $event, $ref_weak_statusbar) = @_;
  ### MessageUntilKey _do_event: $event->type

  # the snooper should be destroyed together with statusbar, but the button
  # hook isn't, so check $ref_weak_statusbar hasn't gone away
  #
  # $statusbar->get_display() is the default display if not under a toplevel
  # (it's never NULL or undef), which means events there will clear
  # unparented statusbars.  Not sure if that's ideal, but close enough for
  # now.

  if ($event->type eq 'key-press' || $event->type eq 'button-press') {
    if (my $statusbar = $$ref_weak_statusbar) {
      if (! $widget->can('get_display')
          || $widget->get_display == $statusbar->get_display) {
        # call through object to allow for subclassing
        if (my $self = $statusbar->{(__PACKAGE__)}) {
          $self->remove ($statusbar);
        }
      }
    }
  }
  return 0; # Gtk2::EVENT_PROPAGATE
}

# 'button-press-event' signal emission hook
sub _do_button_hook {
  my ($invocation_hint, $parameters, $ref_weak_statusbar) = @_;
  my ($widget, $event) = @$parameters;
  _do_event ($widget, $event, $ref_weak_statusbar);
  return 1; # stay connected, remove() does any disconnect
}

1;
__END__

=for stopwords Statusbar multi-display statusbar's statusbar MessageUntilKey Keypresses keypresses clickable unclickable toplevel toplevels unparented Ryde Gtk2-Ex-WidgetBits

=head1 NAME

Gtk2::Ex::Statusbar::MessageUntilKey -- Statusbar message until key or button

=for test_synopsis my ($statusbar)

=head1 SYNOPSIS

 use Gtk2::Ex::Statusbar::MessageUntilKey;
 Gtk2::Ex::Statusbar::MessageUntilKey->message
    ($statusbar, 'Hello World');

=head1 DESCRIPTION

This is an easy way to display a message in a C<Gtk2::Statusbar>,
automatically cleared when the user presses a key or mouse button.  It's
good for the result of a user action, cleared by the next action.

In a multi-display program (multiple C<Gtk2::Gdk::Display>'s) the message is
only cleared by a key or button from the statusbar's own display.
A statusbar can be moved between displays and is cleared only by its current
display.

=head1 FUNCTIONS

=over 4

=item C<< Gtk2::Ex::Statusbar::MessageUntilKey->message ($statusbar, $message) >>

Push string C<$message> onto C<$statusbar> (a C<Gtk2::Statusbar>), and setup
to remove it on the next key press or button press.

If another MessageUntilKey is already displayed in C<$statusbar> then it's
replaced by the new C<$message>.  The new message goes on the top of the
statusbar stack, even if the old one had been buried under other things.

The MessageUntilKey setups only keep a weak reference to C<$statusbar>, so
the mere fact there's a message displayed doesn't keep it alive.

=item C<< Gtk2::Ex::Statusbar::MessageUntilKey->remove ($statusbar) >>

Remove any MessageUntilKey message displayed in C<$statusbar>.  This is
what's done on the next key or button press but you can use this sooner for
explicit removal.  If C<$statusbar> has no MessageUntilKey then C<remove()>
does nothing.

=back

=head1 IMPLEMENTATION

Keypresses are detected with a key snooper, and button presses with a
C<button-press-event> emission hook.  Of course only those delivered to the
program are seen, so keypresses in another program don't clear the message.

A button press in a widget without C<button-press-mask> (meaning something
not normally clickable) doesn't reach the client program and so doesn't
clear anything.  This isn't ideal, but clicking an unclickable isn't really
a new user action, so keeping the message may be reasonable.  One
possibility is to add C<button-press-mask> to the toplevel widget (or all
relevant toplevels), even if it doesn't do anything with buttons, so the
event reaches the client.  Perhaps MessageUntilKey could do that itself, or
try selecting on the root window to pick up button presses anywhere at all.

If a statusbar is not under a toplevel window (C<Gtk2::Window>) then
currently it ends up treated as on the default display
(C<< Gtk2::Gdk::Display->get_default >>) and MessageUntilKey cleared by a
key or button from that display.  Would it be better to leave an unparented
statusbar alone?  Of course when unparented it's not visible, so the
contents aren't important until redisplayed later.

=head1 SEE ALSO

L<Gtk2::Statusbar>,
L<Gtk2::Ex::KeySnooper>,
L<Gtk2::Ex::Statusbar::DynamicContext>

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
