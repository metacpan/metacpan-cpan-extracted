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


package Gtk2::Ex::TiedTreePath;
use 5.008;
use strict;
use warnings;

our $VERSION = 5;

# uncomment this to run the ### lines
#use Smart::Comments;

sub new {
  my ($class, $path) = @_;
  tie (my @array, $class, $path);
  return \@array;
}

sub TIEARRAY {
  my ($class, $path) = @_;
  return bless \$path, $class;
}
# optional, not needed
# sub UNTIE { }

# tied object method
sub path {
  return ${$_[0]};
}

# negative indices already normalized to >=0 by the time they get here
sub FETCH {
  my ($self, $index) = @_;
  ### TiedTreePath FETCH: $index
  return (($$self)->get_indices)[$index];
}

# negative indices already normalized to >=0 by the time they get here
sub STORE {
  my ($self, $index, $value) = @_;
  ### TiedTreePath STORE: [$index, $value]
  my $path = $$self;
  my $depth = $path->get_depth;
  if ($index >= $depth) {
    foreach ($depth .. $index-1) {
      $path->append_index (0);
    }
    $path->append_index ($value);
  } else {
    my @array = $path->get_indices;
    foreach ($index .. $depth-1) {
      $path->up;
    }
    $path->append_index ($value);
    foreach my $i ($index+1 .. $depth-1) {
      $path->append_index ($array[$i]);
    }
  }
}

sub _path_clear {
  my ($path) = @_;
  while ($path->up) {}
}
sub _path_set_indices {
  my $path = shift;
  _path_clear ($path);
  while (@_) { $path->append_index (shift @_); }
}

sub FETCHSIZE {
  my ($self) = @_;
  ### TiedTreePath FETCHSIZE
  return ($$self)->get_depth;
}

# big negative sizes normalized to 0 by the time they get here
sub STORESIZE {
  my ($self, $want_size) = @_;
  ### TiedTreePath STORESIZE: $want_size
  my $path = $$self;
  my $depth = $path->get_depth;
  foreach ($want_size .. $depth-1) {   # shorten
    $path->up;
  }
  foreach ($depth .. $want_size-1) {   # lengthen
    $path->append_index (0);
  }
}

sub EXTEND {
}

# negative indices already normalized to >=0 by the time they get here
sub EXISTS {
  my ($self, $index) = @_;
  ### TiedTreePath EXISTS: $index
  return ($index < ($$self)->get_depth);
}

# normalized to 0 <= $index <= FETCHSIZE-1 by the time get here
sub DELETE {
  my ($self, $index) = @_;
  ### TiedTreePath DELETE: $index
  my $path = $$self;
  my $ret;

  if ($index < (my $depth = $path->get_depth)) {
    $ret = ($path->get_indices)[$index];
    if ($index == $depth-1) {
      $path->up;
    } else {
      $self->STORE ($index, 0);
    }
  }
  return $ret;
}

sub CLEAR {
  my ($self) = @_;
  ### TiedTreePath CLEAR
  _path_clear ($$self);
}

sub PUSH {
  my $self = shift;
  my $path = $$self;
  while (@_) {
    $path->append_index (shift @_);
  }
}

sub POP {
  my ($self) = @_;
  ### TiedTreePath POP
  my $path = $$self;
  my $ret = ($path->get_indices)[-1];
  $path->up;
  return $ret;
}

sub SHIFT {
  my ($self) = @_;
  ### TiedTreePath SHIFT
  my $path = $$self;
  my @array = $path->get_indices;
  if (! @array) { return; }
  my $ret = shift @array;
  ###   $ret
  _path_set_indices ($path, @array);
  return $ret;
}

# don't have to return the new size here, FETCHSIZE is called separately
sub UNSHIFT {
  my $self = shift;
  ### TiedTreePath UNSHIFT
  my $path = $$self;
  push @_, $path->get_indices;
  _path_set_indices ($path, @_);
}

sub SPLICE {
  my $self = shift;
  my $offset = shift;
  my $length = shift;
  ### TiedTreePath SPLICE: [$offset,$length]

  my $path = $$self;
  my @array = $path->get_indices;
  if (wantarray) {
    my @ret = splice @array, $offset, $length, @_;
    _path_set_indices ($path, @array);
    return @ret;
  } else {
    my $ret = splice @array, $offset, $length, @_;
    _path_set_indices ($path, @array);
    return $ret;
  }
}

1;
__END__

=for stopwords TiedTreePath indices natively TreePath perl arrayref funcs Eg Ryde Gtk2-Ex-TiedListColumn

=head1 NAME

Gtk2::Ex::TiedTreePath - tie an array to a Gtk2::TreePath

=head1 SYNOPSIS

 use Gtk2::Ex::TiedTreePath;
 my $path = Gtk2::Path->new;

 my @array;
 tie @array, 'Gtk2::Ex::TiedTreePath', $path;

 my $aref = Gtk2::Ex::TiedTreePath->new ($path);

=head1 DESCRIPTION

TiedTreePath ties a Perl array to a C<Gtk2::TreePath> object so that reading
and writing the array acts on the indices making up the path.

Like most C<tie> things, TiedTreePath is probably better in concept than
actuality.  Being able to store to individual elements is handy, as are Perl
operations like push and pop, but a native C<Gtk2::TreePath> will suffice
for most uses.

=head2 C<delete> and C<exists>

A TreePath has no notion of "exists" on an array element.  If you C<delete>
an element in the middle of the array then it's cleared to 0, but C<exists>
is still true, unlike an ordinary perl array where C<exists> is false in
that case.  The tied C<exists> method simply checks whether the given index
is within the number of indices in the path.

Deleting the endmost element of a TiedTreePath works the same as an ordinary
array though.  In this case the TreePath is shortened with C<< $path->up >>
and C<exists> on that element is then false, being beyond the available
indices.

=head1 FUNCTIONS

=over 4

=item C<tie @var, 'Gtk2::Ex::TiedTreePath', $path>

Tie array variable C<@var> to the given C<$path> (a C<Gtk2::TreePath>) so
C<@var> it accesses the path indices.

=item C<< $arrayref = Gtk2::Ex::TiedTreePath->new ($path) >>

Return an arrayref which is tied to C<$path>.  For example

    my $aref = Gtk2::Ex::TiedTreePath->new ($path);

is the same as

    tie (my @array, 'Gtk2::Ex::TiedTreePath', $path);
    my $aref = \@array;

If you want your own C<@array> as such then the plain C<tie> is easier.  If
you want an arrayref to pass around to other funcs then C<new> saves a line
of code.

=back

=head2 Object Methods

The tie object associated with the array (as returned by the C<tie> or
obtained later with C<tied>) has the following methods.

=over 4

=item C<< $path = $tobj->path >>

Return the underlying C<Gtk2::TreePath> object.  Eg.

    my @array;
    tie @array, 'Gtk2::Ex::TiedTreePath', $path;
    ...
    my $tobj = tied(@array);
    print $tobj->path->to_string;

Or likewise through an arrayref

    my $aref = Gtk2::Ex::TiedTreePath->new($path);
    ...
    my $path = tied(@$aref)->path;

=back

=head1 SEE ALSO

L<Gtk2::TreePath>, L<Gtk2::Ex::TiedListColumn>

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
