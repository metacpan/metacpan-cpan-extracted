# Copyright 2008, 2009, 2010, 2011, 2012, 2014 Kevin Ryde

# This file is part of Glib-Ex-ObjectBits.
#
# Glib-Ex-ObjectBits is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Glib-Ex-ObjectBits is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Glib-Ex-ObjectBits.  If not, see <http://www.gnu.org/licenses/>.

package Glib::Ex::FreezeNotify;
use 5.008;
use strict;
use warnings;
use Scalar::Util;
use Devel::GlobalDestruction 'in_global_destruction';

our $VERSION = 16;

sub new {
  my $class = shift;
  my $self = bless [], $class;
  $self->add (@_);
  return $self;
}

sub add {
  my $self = shift;
  ### FreezeNotify add(): "@_"
  foreach my $object (@_) {
    $object->freeze_notify;
    push @$self, $object;
    Scalar::Util::weaken ($self->[-1]);
  }
}

sub DESTROY {
  my ($self) = @_;
  ### FreezeNotify DESTROY()
  while (@$self) {
    my $object = pop @$self;
    if (defined $object   # possible undef by weakening
        && ! in_global_destruction()) {
      ### FreezeNotify thaw: "$object"
      $object->thaw_notify;
    }
  }
}

1;
__END__

=for stopwords Glib-Ex-ObjectBits FreezeNotify AtExit destructor Ryde ReleaseAction

=head1 NAME

Glib::Ex::FreezeNotify -- freeze Glib object property notifies by scope guard style

=for test_synopsis my ($obj, $obj1, $obj2)

=head1 SYNOPSIS

 use Glib::Ex::FreezeNotify;

 { my $freezer = Glib::Ex::FreezeNotify->new ($obj);
   $obj->set (foo => 123);
   $obj->set (bar => 456);
   # notify signals emitted when $freezer goes out of scope
 }

 # or multiple objects in one FreezeNotify
 {
   my $freezer = Glib::Ex::FreezeNotify->new ($obj1, $obj2);
   $obj1->set (foo => 999);
   $obj2->set (bar => 666);
 }

=head1 DESCRIPTION

C<Glib::Ex::FreezeNotify> applies a C<freeze_notify()> to given objects,
with automatic corresponding C<thaw_notify()> at the end of a block, no
matter how it's exited, whether a C<goto>, early C<return>, C<die>, etc.

This protects against an error throw leaving the object permanently frozen.
Even in simple code an error can be thrown for a bad property name in a
C<set()>, or while calculating a value.  (Though as of Glib-Perl 1.222 an
invalid argument type to C<set()> generally only provokes warnings.)

=head2 Operation

FreezeNotify works by having C<thaw_notify()> in the destroy code of the
FreezeNotify object.

FreezeNotify only holds weak references to its objects, so the mere fact
they're due for later thawing doesn't keep them alive if nothing else cares
whether they live or die.  The effect is that frozen objects can be garbage
collected within a freeze block at the same point they would be without any
freezing, instead of extending their life to the end of the block.

It works to have multiple freeze/thaws, done either with FreezeNotify or
with other C<freeze_notify()> calls.  C<Glib::Object> simply counts
outstanding freezes, which means they don't have to nest, so multiple
freezes can overlap in any fashion.  If you're freezing for an extended time
then a FreezeNotify object is a good way not to lose track of the thaws,
although anything except a short freeze for a handful of C<set_property()>
calls would be unusual.

During "global destruction" phase nothing is done when a FreezeNotify is
destroyed.  The target objects may be already destroyed and not in a fit
state to unthaw.  Perl is exiting so unthawing shouldn't matter.

=head1 FUNCTIONS

=over 4

=item C<< $freezer = Glib::Ex::FreezeNotify->new ($object,...) >>

Do a C<< $object->freeze_notify >> on each given object and return a
FreezeNotify object which, when it's destroyed, will
C<< $object->thaw_notify >> each.  So something like

    $obj->freeze_notify;
    $obj->set (foo => 1);
    $obj->set (bar => 1);
    $obj->thaw_notify;

becomes instead

    { my $freezer = Glib::Ex::FreezeNotify->new ($obj);
      $obj->set (foo => 1);
      $obj->set (bar => 1);
    } # automatic thaw when $freezer goes out of scope

=item C<< $freezer->add ($object,...) >>

Add additional objects to the freezer, calling C<< $object->freeze_notify >>
on each, and setting up for C<< thaw_notify >> the same as in C<new> above.

If the objects to be frozen are not known in advance then it's good to
create an empty freezer with C<new> then add objects to it as required.

=back

=head1 OTHER NOTES

When there's multiple objects in a freezer it's unspecified what order the
C<thaw_notify()> calls are made.  What would be good?  First-in first-out,
or a stack?  You can create multiple FreezeNotify objects and arrange blocks
or explicit discards to destroy them in a particular order if it matters.

There's quite a few general purpose block-scope cleanup systems to do more 
than just thaws.
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

L<Glib::Object>,
L<Glib::Ex::SignalBits>,
L<Glib::Ex::SignalIds>

L<Wx::WindowUpdateLocker>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/glib-ex-objectbits/index.html>

=head1 LICENSE

Copyright 2008, 2009, 2010, 2011, 2012, 2014 Kevin Ryde

Glib-Ex-ObjectBits is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

Glib-Ex-ObjectBits is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Glib-Ex-ObjectBits.  If not, see L<http://www.gnu.org/licenses/>.

=cut
