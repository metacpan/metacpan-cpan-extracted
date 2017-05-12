# Copyright 2008, 2009, 2010, 2011, 2012 Kevin Ryde

# This file is part of Gtk2-Ex-WidgetBits.
#
# Gtk2-Ex-WidgetBits is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-WidgetBits is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-WidgetBits.  If not, see <http://www.gnu.org/licenses/>.

package Gtk2::Ex::FreezeChildNotify;
use 5.008;
use strict;
use warnings;
use Scalar::Util;

our $VERSION = 48;

sub new {
  my $class = shift;
  my $self = bless [], $class;
  $self->add (@_);
  return $self;
}

sub add {
  my $self = shift;
  ### FreezeChildNotify add(): "@_"
  foreach my $widget (@_) {
    $widget->freeze_child_notify;
    push @$self, $widget;
    Scalar::Util::weaken ($self->[-1]);
  }
}

sub DESTROY {
  my ($self) = @_;
  ### FreezeChildNotify DESTROY()
  while (@$self) {
    my $widget = pop @$self;
    next if ! defined $widget; # possible undef by weakening
    ### FreezeChildNotify thaw: "$widget"
    $widget->thaw_child_notify;
  }
}

1;
__END__

=for stopwords Gtk2-Ex-WidgetBits FreezeChildNotify AtExit destructor Ryde Gtk ReleaseAction

=head1 NAME

Gtk2::Ex::FreezeChildNotify -- freeze Gtk child property notifies in scope guard style

=for test_synopsis my ($parent, $widget, $widget1, $widget2)

=head1 SYNOPSIS

 use Gtk2::Ex::FreezeChildNotify;

 { my $freezer = Gtk2::Ex::FreezeChildNotify->new ($widget);
   $parent->child_set_property ($widget, foo => 123);
   $parent->child_set_property ($widget, bar => 456);
   # child-notify signals emitted when $freezer goes out of scope
 }

 # or multiple widgets in one FreezeChildNotify
 {
   my $freezer = Gtk2::Ex::FreezeChildNotify->new ($widget1, $widget2);
   $parent->child_set_property ($widget, foo => 999);
   $parent->child_set_property ($widget, bar => 666);
 }

=head1 DESCRIPTION

C<Gtk2::Ex::FreezeChildNotify> applies a C<freeze_child_notify> to given
widgets, with automatic corresponding C<thaw_child_notify> at the end of a
block, no matter how it's exited, whether a C<goto>, early C<return>,
C<die>, etc.

This protects against an error throw leaving the widget permanently frozen.
Even in a simple bit of code an error can be thrown for a bad property name
in a C<child_set_property>, or while calculating a value.  (Though as of
Glib-Perl 1.222 an invalid argument type to C<child_set_property> generally
only provokes warnings.)

=head2 Operation

FreezeChildNotify works by having C<thaw_child_notify> in the destroy code
of the FreezeChildNotify object.

FreezeChildNotify only holds weak references to its widgets, so the mere
fact they're due for later thawing doesn't keep them alive if nothing else
cares whether they live or die.  The effect is that frozen widgets can be
garbage collected within a freeze block at the same point they would be
without any freezing, instead of extending their life to the end of the
block.

It works to have multiple freeze/thaws, done either with FreezeChildNotify
or with explicit C<freeze_child_notify> calls.  C<Gtk2::Widget> simply
counts outstanding freezes, which means they don't have to nest, so multiple
freezes can overlap in any fashion.  If you're freezing for an extended time
then a FreezeChildNotify object is a good way not to lose track of the
thaws, although anything except a short freeze for a handful of
C<child_set_property> calls would be unusual.

=head1 FUNCTIONS

=over 4

=item C<< $freezer = Gtk2::Ex::FreezeChildNotify->new ($widget,...) >>

Do a C<< $widget->freeze_child_notify >> on each given widget and return a
FreezeChildNotify object which, when it's destroyed, will
C<< $widget->thaw_child_notify >> each.  So something like

    $widget->freeze_child_notify;
    $parent->child_set_property ($widget, foo => 1);
    $parent->child_set_property ($widget, bar => 2);
    $widget->thaw_child_notify;

becomes instead

    { my $freezer = Gtk2::Ex::FreezeChildNotify->new ($widget);
      $parent->child_set_property ($widget, foo => 1);
      $parent->child_set_property ($widget, bar => 2);
    } # automatic thaw when $freezer goes out of scope

=item C<< $freezer->add ($widget,...) >>

Add additional widgets to the freezer, calling
C<< $widget->freeze_child_notify >> on each, and setting up for
C<< thaw_child_notify >> the same as in C<new> above.

If the widgets to be frozen are not known in advance then it's good to
create an empty freezer with C<new> then add widgets as required.

=back

=head1 OTHER NOTES

When there's multiple widgets in a freezer it's unspecified what order the
C<thaw_child_notify> calls are made.  What would be good?  First-in
first-out, or a stack?  You can create multiple FreezeChildNotify objects
and arrange blocks or explicit discards to destroy them in a particular
order if it matters.

C<Glib::Ex::FreezeNotify> does corresponding freezes on plain property
notifies.

There's quite a few general purpose block-scope cleanup systems if you want
more than just thaws.
L<Scope::Guard|Scope::Guard>,
L<AtExit|AtExit>,
L<End|End>,
L<ReleaseAction|ReleaseAction>,
L<Sub::ScopeFinalizer|Sub::ScopeFinalizer>
and L<Guard|Guard> use the destructor style.
L<Hook::Scope|Hook::Scope>
and L<B::Hooks::EndOfScope|B::Hooks::EndOfScope>
manipulate the code in a block.
L<Unwind::Protect|Unwind::Protect> uses an C<eval> and re-throw.

=head1 SEE ALSO

L<Gtk2::Widget>,
L<Glib::Ex::FreezeNotify>

L<Wx::WindowUpdateLocker>

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
