# Copyright 2010 Kevin Ryde

# This file is part of Gtk2-Ex-TiedListColumn.
#
# Gtk2-Ex-TiedListColumn is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-TiedListColumn is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-TiedListColumn.  If not, see <http://www.gnu.org/licenses/>.


package Gtk2::Ex::TiedMenuChildren;
use 5.008;
use strict;
use warnings;
use Carp;
use Gtk2::Ex::ContainerBits;
use List::Util qw(min max);

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 5;

sub new {
  my ($class, $menu) = @_;
  tie (my @array, $class, $menu);
  return \@array;
}

sub TIEARRAY {
  my ($class, $menu) = @_;
  return bless \$menu, $class;
}

# optional, not needed
# sub UNTIE { }

# tied object func
sub menu {
  return ${$_[0]};
}

# negative indices already normalized to >=0 by the time they get here
sub FETCH {
  my ($self, $index) = @_;
  #### TiedChildren FETCH: $index
  return (($$self)->get_children)[$index];
}

# negative indices already normalized to >=0 by the time they get here
sub STORE {
  my ($self, $index, $new) = @_;
  #### TiedChildren STORE: [ $index, $new ]
  my $menu = $$self;

  if (my $old = $self->FETCH ($index)) {
    if ($old == $new) {
      return;  # already what's wanted
    }
    $menu->remove ($old);
  }

  if (defined $new) {
    $menu->insert ($new, $index);
  }
}

sub FETCHSIZE {
  my ($self) = @_;
  ### TiedChildren FETCHSIZE
  my @children = ($$self)->get_children;
  return scalar(@children);
}

# big negative sizes normalized to 0 by the time they get here
sub STORESIZE {
  my ($self, $want_size) = @_;
  ### TiedChildren STORESIZE: $want_size
  ###   currently: $self->FETCHSIZE

  my $menu = $$self;
  my @children = $menu->get_children;
  if ($want_size < @children) {
    Gtk2::Ex::ContainerBits::remove_widgets
        ($menu, splice (@children, $want_size));
  }
}

sub EXTEND {
}

# negative indices already normalized to >=0 by the time they get here
sub EXISTS {
  my ($self, $index) = @_;
  ### TiedChildren EXISTS: $index
  return defined((($$self)->get_children)[$index]);
}

sub DELETE {
  my ($self, $index) = @_;
  ### TiedChildren DELETE: $index
  my $menu = $$self;
  my $ret;
  if ($ret = $self->FETCH ($index)) {  # if such an element
    $menu->remove ($ret);
  }
  return $ret;
}

sub CLEAR {
  my ($self) = @_;
  ### TiedChildren CLEAR
  Gtk2::Ex::ContainerBits::remove_all ($$self);
}

sub PUSH {
  my $self = shift;
  my $menu = $$self;
  while (@_) {
    $menu->append (shift @_);
  }
}

sub POP {
  my ($self) = @_;
  ### TiedChildren POP
  my $menu = $$self;
  my $ret = ($menu->get_children)[-1];
  if (defined $ret) { # if not empty menu
    $menu->remove ($ret);
  }
  return $ret;
}

sub SHIFT {
  my ($self) = @_;
  return DELETE($self, 0);
}

# don't have to return the new size here, FETCHSIZE is called separately
sub UNSHIFT {
  my $self = shift;
  ### TiedChildren UNSHIFT
  my $menu = $$self;
  while (@_) {
    $menu->prepend (pop @_);
  }
}

sub SPLICE {
  my $self = shift;
  my $offset = shift;
  my $length = shift;
  my $menu = $$self;
  my @children = $menu->get_children;
  my $total = scalar @children;

  # carp similar to "use warnings" on ordinary arrays
  if (! defined $offset) {
    $offset = 0;
  } elsif ($offset < -$total) {
    carp "TiedChildren: offset $offset before start of array";
    $offset = 0;
  } elsif ($offset < 0) {
    $offset = $total + $offset;
  } elsif ($offset > $total) {
    carp "TiedChildren: offset $offset past end of array";
    $offset = $total;
  }

  my @ret = splice (@children, $offset, $length);
  Gtk2::Ex::ContainerBits::remove_widgets ($menu, @ret);

  while (@_) {
    $menu->insert (pop @_, $offset);
  }
  ### ret: map {$_->get_name} @ret
  return (wantarray ? @ret : $ret[-1]);
}

1;
__END__

=for stopwords arrayref funcs menu Eg Ryde TiedChildren Gtk2-Ex-TiedListColumn

=head1 NAME

Gtk2::Ex::TiedMenuChildren - tie an array to the items of a Gtk2 menu

=head1 SYNOPSIS

 use Gtk2::Ex::TiedMenuChildren;

 my $menu = Gtk2::Menu->new;
 my @array;
 tie @array, 'Gtk2::Ex::TiedMenuChildren', $menu;

 my $menuitem = $array[3];   # fourth menu item

 my $aref = Gtk2::Ex::TiedMenuChildren->new ($menu);

=head1 DESCRIPTION

C<Gtk2::Ex::TiedMenuChildren> ties an array to the children of
a C<Gtk2::Menu> or C<Gtk2::MenuBar>.  Changes to the children are reflected
in the array, and changes to the array update the menu.

C<push> and C<unshift> correspond to C<append> and C<prepend>.  Storing to
the array is a C<remove()> of the old item at that position and C<insert> of
the new.  Remember an item can only be in one menu at a time.

Like most C<tie> things this is likely better in concept than actual use.
Normally it's enough to C<get_children> and act on that list.

This tie is named for C<Gtk2::Menu> but works with C<Gtk2::MenuBar> or any
C<Gtk2::MenuShell> subclass.  But it can't be used on just any
C<Gtk2::Container> because a plain container doesn't have an "insert" at a
particular position among its children -- that's something only in classes
like MenuShell.

=head2 C<delete> and C<exists>

A menu has no notion of C<undef> in a child item position.  In the current
code a C<delete> removes the item and shuffles the remainder down, which is
unlike a plain Perl array where the rest don't move (see
L<perlfunc/delete>).  C<exists> on a TiedChildren simply reports whether the
array element is within the number of child items.

Deleting the endmost element of a TiedChildren works the same as an ordinary
array though.  In this case the menu is shortened and C<exists> on that
element is false, being beyond the available items.

=head1 FUNCTIONS

In the following C<$menu> is a C<Gtk2::Menu>, C<Gtk2::MenuBar> or other
subclass of C<Gtk2::MenuShell>.

=over 4

=item C<tie @var, 'Gtk2::Ex::TiedMenuChildren', $menu>

Tie array variable C<@var> to the given menu so it accesses the child items
of that widget.

=item C<< Gtk2::Ex::TiedMenuChildren->new ($menu) >>

Return an arrayref which is tied to the child items of C<$menu>.
For example

    my $aref = Gtk2::Ex::TiedMenuChildren->new ($menu);

is the same as

    tie (my @array, 'Gtk2::Ex::TiedMenuChildren', $menu);
    my $aref = \@array;

If you want your own C<@array> then the plain C<tie> is easier.  If you want
an arrayref to pass around to other funcs then C<new> saves a line of code.

=back

=head2 Object Methods

The tie object under the array, as returned by the C<tie> or obtained later
with C<tied>, has the following methods.

=over 4

=item C<< $mtcobj->menu >>

Return the underlying menu widget.  Eg.

    my @array;
    tie @array, 'Gtk2::Ex::TiedMenuChildren', $menu;
    ...
    my $mtcobj = tied(@array);
    print $mtcobj->menu;

Or likewise on an arrayref

    my $aref = Gtk2::Ex::TiedMenuChildren->new($menu);
    ...
    my $menu = tied(@$aref)->menu;

=back

=head1 SEE ALSO

L<Gtk2::Menu>,
L<Gtk2::MenuBar>,
L<Gtk2::MenuShell>

L<Gtk2::Ex::TiedListColumn>,
L<Gtk2::Ex::TiedTreePath>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/gtk2-ex-tiedlistcolumn/>

=head1 COPYRIGHT

Copyright 2010 Kevin Ryde

Gtk2-Ex-TiedListColumn is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3, or (at your option) any
later version.

Gtk2-Ex-TiedListColumn is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
Public License for more details.

You should have received a copy of the GNU General Public License along with
Gtk2-Ex-TiedListColumn.  If not, see L<http://www.gnu.org/licenses/>.

=cut
