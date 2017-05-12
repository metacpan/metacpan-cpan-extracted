# Copyright 2009, 2010, 2011, 2012 Kevin Ryde

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

package Gtk2::Ex::Statusbar::DynamicContext;
use 5.008;
use strict;
use warnings;
use Carp;
use Scalar::Util;

our $VERSION = 48;

# Data hung on each $statusbar:
#
#     $statusbar->{'Gtk2::Ex::Statusbar::DynamicContext.free'}
#         An arrayref containing context strings currently free,
#         ie. available for re-use.
#
#     $statusbar->{'Gtk2::Ex::Statusbar::DynamicContext.seq'}
#         An integer counting upwards to make context strings on $statusbar.
#         Its current value is the most recent number created, so seq+1 is
#         what to create for the next new string.
#
# The context strings are
#
#     Gtk2::Ex::Statusbar::DynamicContext.1
#     Gtk2::Ex::Statusbar::DynamicContext.2
#
# etc.  The seq number in each $statusbar starts at 1.  The same strings are
# used in different $statusbar widgets.  This is fine, a context string only
# has to be unique within a given $statusbar, not globally.
#
# Each string 'Gtk2::Ex::Statusbar::DynamicContext.1' etc ends up going into
# the gtk quark table.  Because each $statusbar effectively uses the same
# strings, in sequence, the quark table only grows to the peak context usage
# of any single statusbar.
#
# $statusbar->{'Gtk2::Ex::Statusbar::DynamicContext.free'} could
# hold an array of integer sequence numbers, or even a bit vector, instead
# of the full context strings.  But the code for that would probably be more
# than any space saved.
#
# The DynamicContext objects are arrays instead of hashes, as think that
# might save a couple of bytes.  Could change if a hash made subclassing
# easier.

sub new {
  my ($class, $statusbar) = @_;
  $statusbar || croak 'No statusbar given';
  my $context_str = pop @{$statusbar->{__PACKAGE__.'.free'}}
    || __PACKAGE__ . '.' . ++$statusbar->{__PACKAGE__.'.seq'};
  my $self = bless [ $statusbar, $context_str ], $class;
  Scalar::Util::weaken ($self->[0]);
  return $self;
}

sub statusbar { return $_[0]->[0] }
sub str       { return $_[0]->[1] }

sub id {
  my ($self) = @_;
  my $statusbar = $self->statusbar;
  return $statusbar && $statusbar->get_context_id ($self->str);
}

sub DESTROY {
  my ($self) = @_;
  if (my $statusbar = $self->statusbar) {
    push @{$statusbar->{__PACKAGE__.'.free'}}, $self->str;
  }
}

1;
__END__

=for stopwords Statusbar DynamicContext runtime DynamicContexts statusbar statusbars Ryde Gtk2-Ex-WidgetBits

=head1 NAME

Gtk2::Ex::Statusbar::DynamicContext -- pool of Gtk2::Statusbar context strings

=for test_synopsis my ($statusbar)

=head1 SYNOPSIS

 use Gtk2::Ex::Statusbar::DynamicContext;
 my $dc = Gtk2::Ex::Statusbar::DynamicContext->new
              ($statusbar);
 $statusbar->push ($dc->id, 'Some message');
 $statusbar->pop  ($dc->id);

=head1 DESCRIPTION

A DynamicContext object is a generated context string and ID number for a
C<Gtk2::Statusbar> widget.  It's designed for message sources or contexts
which are created and destroyed dynamically at runtime.

Usually you don't need a dynamic context.  Most libraries or parts of a
program can just take something distinctive from their name as a context
string.  For example a Perl package name, or package name plus component.

    # fixed id for package
    $id = $statusbar->get_context_id(__PACKAGE__.'.warning');

Dynamic context is when you do something like spawn multiple object
instances each of which might display a status message.  In that case they
need a separate context string each.

    # dynamic id for each instance of a package
    $obj = MyPackage->new;
    $obj->{'dc'} = Gtk2::Ex::Statusbar::DynamicContext->new($statusbar);
    $id = $obj->{'dc'}->id;

When a DynamicContext object is garbage collected the string is returned to
a pool for future re-use on the Statusbar widget.  This is important for a
long-running program because a context string and its ID in a Statusbar are
permanent additions to the memory of that widget and to the global quark
table.  That means a simple approach like sequentially numbered context
strings is not enough, it would consume ever more memory.  With
DynamicContext style re-use the space is capped at the peak number of
contexts used at any one time.

=head2 Weakening

DynamicContext only holds a weak reference to its C<$statusbar>, so the mere
fact a message context exists doesn't keep the Statusbar alive.

=head1 FUNCTIONS

=over 4

=item C<< $dc = Gtk2::Ex::Statusbar::DynamicContext->new ($statusbar) >>

Create and return a new DynamicContext object for C<$statusbar> (a
C<Gtk2::Statusbar> widget).

=item C<< $id = $dc->id() >>

Return the context ID (an integer) from C<$dc>.  It can be used with
C<< $statusbar->push >> etc.

    $statusbar->push ($dc->id, 'Some message');

If the statusbar has been garbage collected then the return from C<id()> is
unspecified.

=item C<< $str = $dc->str() >>

Return the context description string from C<$dc>.  This is not often
needed, usually the integer C<id()> is enough.  In the current
implementation the string is like

    "Gtk2::Ex::Statusbar::DynamicContext.123"

but don't depend on its exact form, only that it's unique within the target
C<$statusbar>.  The C<id()> method above is simply

    $statusbar->get_context_id($dc->str)

DynamicContext strings are unique within the particular C<$statusbar> but
are not globally unique, ie. the same string might be used by another
DynamicContext object on another statusbar.  Doing so keeps down the size of
the Glib quark table.

=item C<< $statusbar = $dc->statusbar() >>

Return the C<Gtk2::Statusbar> from C<$dc>.  If the statusbar has been
garbage collected then this is C<undef>.

=back

=head1 SEE ALSO

L<Gtk2::Statusbar>,
L<Scalar::Util/weaken>

L<Gtk2::Ex::Statusbar::Message>,
L<Gtk2::Ex::Statusbar::MessageUntilKey>

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
