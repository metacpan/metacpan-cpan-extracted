# Copyright 2008, 2009, 2010 Kevin Ryde

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


package Gtk2::Ex::TiedListColumn;
use 5.008;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);

our $VERSION = 5;

use constant DEBUG => 0;

sub new {
  my ($class, $model, $column) = @_;
  tie (my @array, $class, $model, $column);
  return \@array;
}

sub TIEARRAY {
  my ($class, $model, $column) = @_;
  return bless { model  => $model,
                 column => ($column||0)
               }, $class;
}
# optional, not needed
# sub UNTIE { }

# tied object funcs
sub model {
  my ($self) = @_;
  return $self->{'model'};
}
sub column {
  my ($self) = @_;
  return $self->{'column'};
}

# negative indices already normalized to >=0 by the time they get here
sub FETCH {
  my ($self, $index) = @_;
  if (DEBUG >= 2) { print "FETCH $index\n"; }
  my $model = $self->{'model'};
  my $iter = $model->get_iter (Gtk2::TreePath->new ($index))
    || return undef;
  return $model->get_value ($iter, $self->{'column'});
}

# negative indices already normalized to >=0 by the time they get here
sub STORE {
  my ($self, $index, $value) = @_;
  if (DEBUG) { print "STORE $index $value\n"; }
  my $model = $self->{'model'};
  my $iter = $model->get_iter (Gtk2::TreePath->new ($index));
  if (! $iter) {
    my $len = $model->iter_n_children (undef);
    while ($len <= $index) {
      $iter = $model->insert ($len);
      $len++;
    }
  }
  $model->set_value ($iter, $self->{'column'}, $value);
}

sub FETCHSIZE {
  my ($self) = @_;
  if (DEBUG) { print "FETCHSIZE\n"; }
  my $model = $self->{'model'};
  return $model->iter_n_children (undef);
}

# big negatives already normalized to 0 by the time they get here
sub STORESIZE {
  my ($self, $want_size) = @_;
  if (DEBUG) { print "STORESIZE $want_size, currently ",
                 $self->{'model'}->iter_n_children (undef),"\n"; }
  my $model = $self->{'model'};
  my $got_size = $model->iter_n_children (undef);
  while ($got_size < $want_size) {
    $model->append;
    $got_size++;
  }
  while ($got_size > $want_size) {
    my $iter = $model->get_iter (Gtk2::TreePath->new($got_size-1));
    $model->remove ($iter);
    $got_size--;
  }
}

sub EXTEND {
}

# negative indices already normalized to >=0 by the time they get here
sub EXISTS {
  my ($self, $index) = @_;
  if (DEBUG) { print "EXISTS $index\n"; }
  my $model = $self->{'model'};
  return $index < $model->iter_n_children(undef);
}

sub DELETE {
  my ($self, $index) = @_;
  if (DEBUG) { print "DELETE $index\n"; }
  my $model = $self->{'model'};

  my $iter = $model->get_iter (Gtk2::TreePath->new ($index))
    || return undef;
  my $ret = $model->get_value ($iter);
  my $len = $model->iter_n_children (undef);
  if ($index == $len-1) {
    $model->remove ($iter);
  } else {
    $model->set ($iter, $self->{'column'}, undef);
  }
  return $ret;
}

sub CLEAR {
  my ($self) = @_;
  if (DEBUG) { print "CLEAR\n"; }
  my $model = $self->{'model'};
  $model->clear;
}

sub PUSH {
  my $self = shift;
  my $model = $self->{'model'};
  my $column = $self->{'column'};
  my $pos = $model->iter_n_children (undef);
  foreach my $value (@_) {
    $model->insert_with_values ($pos++, $column, $value);
  }
}

sub POP {
  my ($self) = @_;
  if (DEBUG) { print "POP\n"; }
  my $model = $self->{'model'};
  my $len = $model->iter_n_children (undef) || return undef; # if empty
  my $iter = $model->iter_nth_child (undef, $len-1);
  my $value = $model->get_value ($iter, $self->{'column'});
  $model->remove ($iter);
  return $value;
}

sub SHIFT {
  my ($self) = @_;
  my $model = $self->{'model'};
  my $iter = $model->get_iter_first || return undef; # if empty
  my $value = $model->get_value ($iter, $self->{'column'});
  $model->remove ($iter);
  return $value;
}

# don't have to return the new size here, FETCHSIZE is called separately
sub UNSHIFT {
  my $self = shift;
  if (DEBUG) { print "UNSHIFT\n"; }
  my $model = $self->{'model'};
  my $column = $self->{'column'};
  my $pos = 0;
  foreach my $value (@_) {
    $model->insert_with_values ($pos++, $column, $value);
  }
}

sub SPLICE {
  my $self = shift;
  my $offset = shift;
  my $length = shift;
  if (DEBUG) { print "SPLICE ",defined $offset ? $offset : 'undef',
                 " ", defined $length ? $length : 'undef', "\n"; }

  my $model = $self->{'model'};
  my $column = $self->{'column'};
  my $total = $model->iter_n_children (undef);

  # carp similar to "use warnings" on ordinary arrays
  if (! defined $offset) {
    $offset = 0;
  } elsif ($offset < -$total) {
    carp "TiedListColumn: offset $offset before start of array";
    $offset = 0;
  } elsif ($offset < 0) {
    $offset += $total;
  } elsif ($offset > $total) {
    carp "TiedListColumn: offset $offset past end of array";
    $offset = $total;
  }

  if (! defined $length) {
    $length = $total - $offset;
  } elsif ($length < 0) {
    $length = max (0, $total + $length - $offset);
  } else {
    $length = min ($length, $total - $offset);
  }

  if (DEBUG) { print "  norm to $offset, $length\n"; }

  my @ret;
  if ($length > 0) {
    my $iter = $model->iter_nth_child (undef, $offset);
    if (wantarray) {
      $#ret = $length-1;
      foreach my $i (0 .. $length-1) {
        $ret[$i] = $model->get_value ($iter, $column);
        $model->remove ($iter) or last;
      }

    } else {
      $ret[0] = undef;
      foreach (0 .. $length-2) {
        if (! $model->remove ($iter)) {
          $iter = undef;
          last;
        }
      }
      if ($iter) {
        $ret[0] = $model->get_value ($iter, $column);
        $model->remove ($iter);
      }
    }
  }

  foreach my $value (@_) {
    $model->insert_with_values ($offset++, $column, $value);
  }

  # here in scalar context $ret[0] is the last removed as per what splice()
  # should return
  return (wantarray ? @ret : $ret[0]);
}

1;
__END__

=head1 NAME

Gtk2::Ex::TiedListColumn - tie an array to a column of a list TreeModel

=head1 SYNOPSIS

 use Gtk2::Ex::TiedListColumn;
 # any sort of model ...
 my $my_model = Gtk2::ListStore->new ('Glib::String');

 my @array;
 tie @array, 'Gtk2::Ex::TiedListColumn', $my_model, 0;

 my $aref = Gtk2::Ex::TiedListColumn->new ($my_model, 5);

=head1 DESCRIPTION

TiedListColumn ties an array to a single column of a list-type
C<Gtk2::TreeModel> object so that reading from the array reads from the
model.  If the model implements modification functions like C<set>,
C<insert> and C<remove> in the style of C<Gtk2::ListStore> then writing to
the array modifies the model too.

Most C<tie> things tend to be better in concept than actuality and
TiedListColumn is no exception.  The benefit is being able to apply generic
array algorithms to data in a model, eg. a binary search, uniqifying, or
perl's array slice manipulation.  As a starting point it's good, but a tie
is a fair slowdown and model access is not very fast anyway, so for big
crunching you're likely to end up copying data out to an ordinary array
anyway.  (See C<column_contents> in C<Gtk2::Ex::TreeModelBits> for help on
that).

=head2 C<delete> and C<exists>

A TreeModel has no per-row notion of "exists".  If you C<delete> an element
in the middle of the array then it's cleared to C<undef>, but C<exists> is
still true, unlike an ordinary perl array where C<exists> is false in that
case.  (The tied C<exists> method simply checks whether the given index is
within the number of rows in the model.)

Deleting the endmost element of a TiedListColumn works the same as an
ordinary array though.  In this case the row is removed from the model,
shortening it, and C<exists> is then false (beyond the end of the model).

=head2 Other Ways To Do It

TiedListColumn differs from C<Gtk2::Ex::TiedList> (part of
C<Gtk2::Ex::Simple::List>) in presenting just a single column of the model,
whereas TiedList gives array elements which are TiedRow objects presenting a
sub-array of all the values in the row.  TiedListColumn is good if your
model only has one column, or only one you're interested in.

TiedListColumn uses C<insert_with_values> in various places.  That function
is only available for C<Gtk2::ListStore> in Gtk 2.6 and higher, so ensure
your Gtk is new enough if you're extending a tied ListStore (C<push>,
C<unshift>, or C<splice> insertion).

=head1 FUNCTIONS

=over 4

=item C<tie @var, 'Gtk2::Ex::TiedListColumn', $model>

=item C<tie @var, 'Gtk2::Ex::TiedListColumn', $model, $column>

Tie array variable C<@var> to the given C<$model> so it accesses the model
contents in C<$column>.  The default column is 0, which is the first column.

C<$model> can be any Glib object implementing the C<Gtk2::TreeModel>
interface.  It's expected to be a list style model, but currently that's not
enforced.

=item C<< Gtk2::Ex::TiedListColumn->new ($model) >>

=item C<< Gtk2::Ex::TiedListColumn->new ($model, $column) >>

Return an arrayref which is tied to C<$model> and C<$column> (default 0).
For example

    my $aref = Gtk2::Ex::TiedListColumn->new ($model, 6);

is the same as

    tie (my @array, 'Gtk2::Ex::TiedListColumn', $model, 6);
    my $aref = \@array;

If you want your own C<@array> as such then the plain C<tie> is easier.  If
you want an arrayref to pass around to other funcs then C<new> saves a line
of code.

=back

=head2 Object Methods

The tie object associated with the array (as returned by the C<tie> or
obtained later with C<tied>) has the following methods.

=over 4

=item C<< $tlcobj->model >>

=item C<< $tlcobj->column >>

Return the underlying model object or column number.  Eg.

    my @array;
    tie @array, 'Gtk2::Ex::TiedListColumn', $model;
    ...
    my $tlcobj = tied(@array);
    print $tlcobj->column;  # column 0

Or likewise through an arrayref

    my $aref = Gtk2::Ex::TiedListColumn->new($model);
    ...
    my $model = tied(@$aref)->model;

=back

=head1 SEE ALSO

L<Gtk2::TreeModel>, L<Gtk2::Ex::Simple::List> (for
C<Gtk2::Ex::Simple::TiedList>), L<Gtk2::Ex::TiedTreePath>,
L<Gtk2::Ex::TreeModelBits>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/gtk2-ex-tiedlistcolumn/>

=head1 COPYRIGHT

Copyright 2008, 2009, 2010 Kevin Ryde

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
