# Copyright 2018, 2019, 2020, 2021 Kevin Ryde
#
# This file is part of Graph-Maker-Other.
#
# This file is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# This file is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Graph-Maker-Other.  See the file COPYING.  If not, see
# <http://www.gnu.org/licenses/>.


package Graph::Maker::CatalansUpto;
use 5.004;
use strict;
use constant 1.02;
use Carp 'croak';
use Graph::Maker;

use Graph::Maker::Catalans;
*_balanced_next = \&Graph::Maker::Catalans::_balanced_next;

use vars '$VERSION','@ISA';
$VERSION = 19;
@ISA = ('Graph::Maker');


# uncomment this to run the ### lines
# use Smart::Comments;


#---------
# Below

use constant _rel_type_name_below => 'Below';
sub _rel_type_below {
  my ($aref) = @_;
  my @ret;
  foreach my $i (0 .. scalar(@$aref)) {
    unless ($aref->[$i]) { 
      my @to = @$aref;
      splice @to, $i,0, 1,0;    # (0 or end) -> 10 (0 or end)
      push @ret, \@to;
    }
  }
  return @ret;
}

#---------
# Insert

use constant _rel_type_name_insert => 'Insert';
sub _rel_type_insert {
  my ($aref) = @_;
  ### _rel_type_insert(): join(',',@$aref)
  unless (@$aref) {
    return [1,0];
  }
  my @ret;
  foreach my $i (0 .. $#$aref-1) {
    if ($aref->[$i]) {
      #      *             *         *            *             *
      #     / \   ->      / \       / \          / \           / \
      #    A   B         *   B     *   B        A   *         A   *
      #                 /           \              /               \
      #                A             A            B                 B
      #                   LL        LR           RL             RR
      #
      #   1 A 0 1bb0   11 A 00 B   110 A 0 B    1A0 1B0     1A0 10 B
      #   i   j      k
      #
      #   1 10 0       11 10 00    110 10 0                 1100 10
      #   i    j
      #
      #   1 10 0                                            1 10 10 0 = LR
      #     ij
      #
      # ENHANCE-ME: Conditions for when some inserts are same as others.
      # A-empty and B-empty is LL=LR and RL=RR.  
      # A-empty can RR at the last 10 of the run of rights.
      # B-empty can LL at just one of the nested 111 10 1..0 000 run of lefts
      # LR = RR insert at different places in 1100.

      my $j = Graph::Maker::Catalans::_balanced_end($aref,$i);
      my $k = _balanced_multi_end($aref,$j+1);
      ### $i
      ### $j
      ### $k

      # if ($j==$i+1
      #     || Graph::Maker::Catalans::_balanced_end($aref,$i+1) != $j-1)
      {
        my @to = @$aref;
        splice @to, $j,0, 0;
        splice @to, $i,0, 1;
        push @ret, \@to;
        ### LL: join(',',@to)
      }

      # LR, when A not empty so not same as LL
      # if ($j!=$i+1)
      {
        my @to = @$aref;
        splice @to, $i+1,0, 1,0;
        push @ret, \@to;
        ### LR: join(',',@to)
      }

      # RL
      {
        my @to = @$aref;
        splice @to, $k,0, 0;
        splice @to, $j+1,0, 1;
        push @ret, \@to;
      }

      # unless ($aref->[$j+1] && !$aref->[$j+2])
      {
        ### RR ...
        my @to = @$aref;
        splice @to, $j+1,0, 1,0;
        ### RR: join(',',@to)
        push @ret, \@to;
      }
    }

    #   {
    #     my @to = @$aref;
    #     splice @to, $i+1,0, 1,0;    # A right child
    #     push @ret, \@to;
    #   }
    # } else {
    #   #    *               *             *
    #   #   / \       ->    / \             \
    #   #  A   A               *             *
    #   #     / \             /               \
    #   #                    A                 A
    #   #                   / \               / \
    #   #
    #   #   0 1a0 1a0      0 1 1a0 1a0 0   0 10 1a0 1a0
    #   #   i       j        ^         ^
    #   unless ($aref->[$i] && !$aref->[$i+1]) {
    #     my $j = _balanced_multi_end($aref,$i+1);
    #     my @to = @$aref;
    #     splice @to, $j,0, 0;        # left child
    #     splice @to, $i,0, 1;
    #     push @ret, \@to;
    #   }
    #   unless ($aref->[$i-1]) {
    #   }
    # }

  }
  my %seen;
  return grep {!$seen{join('',@$_)}++} @ret;
}

my @pm_one = (-1, 1);

# $aref is an arrayref to balanced binary 0s and 1s.
# $i is index into $aref, or possibly past the end.
# Return the position after any balanced substrings at and after $i.
#
#   1 10 10 10 0       10 10       10 10   
#        ^     ^        ^                ^      
#        i    ret       i = ret          i = ret
#
# If $aref->[$i] == 1 then that is a balanced substring and the return is
# after all such, meaning the first descent below that i level, or 1 past
# end of $aref.
#
# If $aref->[$i] == 0 then there are no balanced substrings and the return
# is $i unchanged.  Likewise if $i is past the end of string already.
#
sub _balanced_multi_end {
  my ($aref, $i) = @_;
  ### _balanced_multi_end(): $i
  my $d = 0;
  while ($i <= $#$aref) {
    if (($d += $pm_one[$aref->[$i]]) < 0) {
      last;
    }
    $i++;
  }
  return $i;
}

use constant _rel_type_name_insert_right => 'Insert Right';
sub _rel_type_insert_right {
  my ($aref) = @_;
  my @ret;
  foreach my $i (0 .. scalar(@$aref)) {
    unless ($aref->[$i] && ! $aref->[$i+1]) {
      my @to = @$aref;
      splice @to, $i,0, 1,0;
      push @ret, \@to;
    }
  }
  return @ret;
}

# =head2 Insert
# 
# Option C<rel_type =E<gt> 'insert'> is graph edge where a vertex is added
# at an empty position like C<below>, or also inserted into an edge.  For
# the latter, the existing subtree below becomes either left or right child
# of the new vertex.
#
# In balanced binary, C<subdivide_right> is insert a 10 anywhere, including
# start or end of string.  Some such insertions give the same same
# destination.  Just one edge to each distinct destination is made.  The
# rule for that is do not insert before a 10, since inserting after it will
# be the same.  In a run of 101010 the insert is only after the last.


#------------------

sub init {
  my ($self, %params) = @_;
  ### Catalans init ...

  my $N = delete($params{'N'}) || 0;

  my $rel_type = delete($params{'rel_type'}) || 'below';
  my $rel_type_func = $self->can("_rel_type_$rel_type")
    || croak "Unrecognised rel_type: ",$rel_type;

  my $rel_direction = delete($params{'rel_direction'}) || 'up';

  my $vertex_name_type = delete($params{'vertex_name_type'}) || 'balanced';
  my $order = delete($params{'order'}) || 'pre';
  my $vertex_name_func
    = Graph::Maker::Catalans->can("_vertex_name_type_$vertex_name_type")
    || croak "Unrecognised vertex_name_type: ",$vertex_name_type;

  my $comma = delete($params{'comma'});
  unless (defined $comma) {
    $comma = ($vertex_name_type eq 'balanced'
              || $vertex_name_type eq 'balanced_postorder'
              ? '' : ',');
  }

  my $graph = Graph::Maker::Catalans::_make_graph(\%params);
  $graph->set_graph_attribute
    (name => "Catalans Upto N=$N, "
     . $self->can("_rel_type_name_$rel_type")->());

  unless ($graph->is_directed) {
    $rel_direction = 'up';
  }
  my $up   = ($rel_direction ne 'down');
  my $down = ($rel_direction ne 'up');

  foreach my $len (0 .. $N-1) {
    my @array = (1,0) x $len;
    do {
      my $from = join($comma,$vertex_name_func->(\@array));
      $graph->add_vertex($from);

      ### array: join('',@array)
      ### $from
      foreach my $to_aref ($rel_type_func->(\@array)) {
        my $to = join($comma,$vertex_name_func->($to_aref));
        ### to array: join('',@$to_aref)
        ### $to
        if ($up)   { $graph->add_edge($from,$to); }
        if ($down) { $graph->add_edge($to,$from); }
      }
    } while (_balanced_next(\@array));
  }
  {
    # size N, if for any reason no edges to them
    my @array = (1,0) x $N;
    do {
      my $from = join($comma,$vertex_name_func->(\@array));
      $graph->add_vertex($from);
    } while (_balanced_next(\@array));
  }

  return $graph;
}

Graph::Maker->add_factory_type('Catalans_upto' => __PACKAGE__);
1;

__END__

=for stopwords Ryde Catalan Catalans CatalansUpto coderef undirected OEIS postorder successorless

=head1 NAME

Graph::Maker::CatalansUpto - create graphs of Catalan object growth

=for test_synopsis my ($graph)

=head1 SYNOPSIS

 use Graph::Maker::CatalansUpto;
 $graph = Graph::Maker->new ('Catalans_upto', N => 4);

=head1 DESCRIPTION

C<Graph::Maker::CatalansUpto> creates C<Graph.pm> graphs where each vertex
represents a "Catalan object".  See L<Graph::Maker::Catalans> for
description and for C<vertex_name_type> options.  The number of vertices is
sum Catalan numbers

    num vertices = sum k=0 to N of Catalan(k)
                 = 1, 2, 4, 9, 23, 65, ...   (A014137)

Edges are where a Catalan object grows to a bigger such object under some
rule.

=head2 Below

Option C<rel_type =E<gt> 'below'> is graph edge extending a binary tree by
adding a new vertex below, at an otherwise empty child position.  Stanley
considers this as lattice of order ideals of a complete binary tree.

=over

Richard P. Stanley, "The Fibonacci Lattice", Fibonacci Quarterly, volume 13,
number 3, October 1975, pages 215-232, lattice A2 = J(T2) page 224.
L<https://fq.math.ca/13-3.html>,
L<https://fq.math.ca/Scanned/13-3/stanley.pdf>

=back

In terms of balanced binary, adding below is to insert 10 before 0 or at end
of string.

    from     (0 or end-of string)
     to   10 (0 or end-of string)

                         ----> 101010
                        /  --> 101100
                       |  /
                  /--> 1010---v             N => 3
    [empty] --> 10             110010       rel_type => "below"
                  \--> 1100---^
                       |  \
                        \  --> 110100
                         ----> 111000

Each length 2k string has k 0s plus the end so k+1 successors each vertex.

    num edges = sum k=0 to N-1 of (k+1)*Catalan(k)
              = 0, 1, 3, 9, 29, 99, ...    (A006134)

=cut

# GP-DEFINE  Catalan_number(n) = binomial(n<<1,n) / (n+1);
# GP-DEFINE  BelowNumEdges(N) = sum(k=0,N-1, (k+1)*Catalan_number(k));
# GP-Test  vector(6,N,N--; BelowNumEdges(N)) == [0, 1, 3, 9, 29, 99]

=pod

The number of paths from start up to a successorless end is choice k+1 at
each vertex so paths = 1*2*...*N = N!.

=head1 FUNCTIONS

=over

=item C<$graph = Graph::Maker-E<gt>new('Catalans', key =E<gt> value, ...)>

The key/value parameters are

    N            => integer, trees sizes 0 to N inclusive
    graph_maker  => subr(key=>value) constructor,
                     default Graph->new

    rel_type     => string
      "below" (default)

    rel_direction     => string  \
    comma             => string  | see Graph::Maker::Catalans
    vertex_name_type  => string  /


Other parameters are passed to the constructor, either the C<graph_maker>
coderef or C<Graph-E<gt>new()>.

If the graph is directed (the default) then edges are only in the
"successor" direction for the given C<rel_type>.

=back

=head1 HOUSE OF GRAPHS

House of Graphs entries for graphs here include

=over

L<https://hog.grinvin.org/ViewGraphInfo.action?id=1310>  etc

=back

    all rel_type
      1310   N=0, singleton
      19655  N=1, path-2

    below
      340    N=2, star-4, claw

=head1 OEIS

Entries in Sloane's Online Encyclopedia of Integer Sequences related to
this tree include

=over

L<http://oeis.org/A000108> (etc)

=back

    A014137    num vertices, cumulative Catalan numbers
    A000108    row widths, Catalan numbers

    below
      A006134    num edges
      A000142    num paths start to successorless, N!

=head1 SEE ALSO

L<Graph::Maker>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/graph-maker-other/index.html>

=head1 LICENSE

Copyright 2018, 2019, 2020, 2021 Kevin Ryde

This file is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

This file is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
This file.  If not, see L<http://www.gnu.org/licenses/>.

=cut
