# Copyright 2015, 2016, 2017 Kevin Ryde
#
# This file is part of Graph-Graph6.
#
# Graph-Graph6 is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Graph-Graph6 is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with Graph-Graph6.  If not, see <http://www.gnu.org/licenses/>.

package Graph::DIMACS;
use 5.006;  # for 3-arg open
use strict;
use warnings;

use Exporter;
our @ISA = ('Exporter');
our @EXPORT_OK = ('read_graph','write_graph');

our $VERSION = 8;

# uncomment this to run the ### lines
# use Smart::Comments;


sub read_graph {
  my %options = @_;
  my $error;

  my $fh = $options{'fh'};
  if (defined $options{'str'}) {
    require IO::String;
    $fh = IO::String->new($options{'str'});
  }

  # Return 1 if good.
  # Return empty list and $error=string if something bad.
  # Return empty list and $error=undef if EOF.
  my $read = sub {

    if (! defined $fh) {
      if (defined(my $filename = $options{'filename'})) {
        unless (open $fh, '<', $filename) {
          $error = "Cannot open file $filename: $!";
          return;
        }
        unless (binmode($fh)) {
          $error = "Cannot binmode: $!";
          return;
        }
      }
    }

    my $binary;
    my $num_vertices = -1;
    my $num_edges = -1;
    my $comments = '';
    my $got_num_edges = 0;

    my $edge_func = $options{'edge_func'};
    my $edge_aref = $options{'edge_aref'};
    if ($edge_aref) { @$edge_aref = (); }

    for (;;) {
      my $line = getline $fh;
      if (! defined $line) {  # EOF
        if ($binary) {
          $error = "Unexpected end of file";
          return;
        }
        last;
      }
      $line =~ tr/\r//d;   # possible CRs if reading as binmode

      if ($line =~ /^\d+$/) {
        ### binary ...
        $binary = 1;

      } elsif ($line =~ /^(c ?)/) {
        $comments .= substr($line, length($1));

      } elsif ($line =~ /^e (\d+) (\d+)$/) {
        chomp $line;
        my ($i,$j) = split / /, substr($line,2); # keep taint of $line
        if ($edge_func) { $edge_func->(      $i, $j); }
        if ($edge_aref) { push @$edge_aref, [$i, $j]; }
        $got_num_edges++;

      } elsif ($line =~ /^p (\S+) (\d+) (\d+)$/) {
        my $type = $1;
        unless ($type eq 'edge') {
          $error = "Unrecognised problem type: $type";
          return;
        }

        $num_vertices = $2;
        $num_edges = $3;
        ### $num_vertices
        ### $num_edges

        if (my $num_vertices_func = $options{'num_vertices_func'}) {
          $num_vertices_func->($num_vertices);
        }
        if (my $num_vertices_ref = $options{'num_vertices_ref'}) {
          $$num_vertices_ref = $num_vertices;
        }

        if ($binary) {
          ### p binary ...

          foreach my $i (1 .. $num_vertices) {
            my $len = ($i+7) >> 3;
            my $buf;
            if (! defined (read $fh, $buf, $len)) {
              $error = "Extra bytes at end of file";
              return;
            }
            unless (length($buf) == $len) {
              $error = "Unexpected end of file";
              return;
            }
            my $taint = '0'.substr($buf,0,0);
            my $i_taint = $i + $taint;

            foreach my $j (0 .. $i-1) {
              # vec() takes bits little endian, $buf is big endian, ^7 to adjust.
              if (vec $buf, $j^7, 1) {
                ### edge: "$i - $j"
                my $j_taint = $j + 1 + $taint;
                if ($edge_func) { $edge_func->(      $i_taint, $j_taint); }
                if ($edge_aref) { push @$edge_aref, [$i_taint, $j_taint]; }
                $got_num_edges++;
              }
            }
          }

          ### rest: (-s $fh) - tell($fh)
          # sum(i=1,171, ceil(i/8)) == 1914
          # 1914

          unless (read($fh, my $buf, 1) == 0) {
            $error = "Extra bytes at end of file";
            return;
          }
          last;
        }

      } else {
        $error = "Unrecognised line: $line";
        return;
      }
    }

    ### $comments
    if (my $comments_func = $options{'comments_func'}) {
      $comments_func->($comments);
    }
    if (my $comments_ref = $options{'comments_ref'}) {
      $$comments_ref = $comments;
    }

    if ($num_edges != $got_num_edges) {
      $error = "Oops, p line $num_edges edges but saw $got_num_edges";
    }
    return 1;
  };

  if ($read->()) {
    return 1;  # successful read
  }
  if (defined $error) {
    ### $error
    my $error_func = $options{'error_func'} || do {
      require Carp;
      \&Carp::croak
    };
    $error_func->($error);
    return undef;
  }
  return 0;  # EOF
}

1;
__END__

=for stopwords Ryde undirected multi-edges arrayref tty

=head1 NAME

Graph::DIMACS - read DIMACS format graphs

=head1 SYNOPSIS

 use Graph::DIMACS;
 my ($num_vertices, @edges);
 Graph::DIMACS::read_graph(filename         => 'foo.clq',
                           num_vertices_ref => \$num_vertices,
                           edge_aref        => \@edges);

=head1 DESCRIPTION

This module reads DIMACS format graph files, either text or binary form.

Text or binary is detected automatically.  Both represent a graph with
vertices numbered 1 to n.  The text form is edges given one per line.  The
binary form is a text header followed by an upper triangular adjacency
matrix of bits.  Both can have self-loops.  The text form can have
multi-edges.

Various DIMACS challenges have further information in the file.  The current
code reads enough for the clique challenge.

=head1 FUNCTIONS

=head2 Reading

=over

=item C<$success = Graph::DIMACS::read_graph(key =E<gt> value, ...)>

Read DIMACS text or binary graph.  The key/value options are

    filename           => filename (string)
    fh                 => filehandle (glob ref)
    str                => string
    num_vertices_ref   => scalar ref
    num_vertices_func  => coderef
    edge_aref          => array ref
    edge_func          => coderef
    error_func         => coderef
    comments_ref       => scalar ref
    comments_func      => coderef

The return value is

    1         if graph successfully read
    0         if end of file (no graph)
    croak()   if invalid content or file error
    undef     if error_func returns instead of dying

C<filename>, C<fh> or C<str> is the input.  The output is the number of
vertices and a list of edges.  For binary input C<fh> should be in a
suitable C<binmode()> already and C<str> should generally be bytes rather
than wide-chars.

The number of vertices n is stored to C<num_vertices_ref> or call to
C<num_vertices_func>, or both.

    $$num_vertices_ref = $n;
    $num_vertices_func->($n);

Each edge is pushed onto C<edge_aref> or call to C<edge_func>, or both.
C<$from> and C<$to> are integers in the range 1 to n.  Any previous contents
of C<edge_aref> are discarded.

    push @$edge_aref, [ $from, $to ];
    $edge_func->($from, $to);

C<error_func> is called for any file error or invalid content.

    $error_func->($str, $str, ...);

The default C<error_func> is C<croak()>.  If C<error_func> returns then the
return from C<read_graph()> is C<undef>.

For C<num_vertices_ref> and C<edge_aref> a C<my> can be included in the
ref-taking in the usual way if desired,

    # "my" included in refs
    read_graph(filename         => 'foo.clq.b',
               num_vertices_ref => \my $num_vertices,
               edge_aref        => \my @edges);

This is compact and is similar to the common C<open my $fh, ...> declaring
an output variable in the call which is its first use.

=cut

# The file formats have edges ordered by increasing C<$to> and within that
# increasing C<$from>, though for sparse6 C<$from> can potentially jump
# around.  But the suggestion is not to rely on edge order (only on C<$from
# E<lt>= $to> noted above).

=pod

In C<perl -T> taint mode, C<$num_vertices>, C<$comments> and edge
C<$from,$to> outputs are tainted in the usual way when reading a file, a
tainted C<str>, or an C<fh> handle to a file or a tie of something tainted.

=back

=head1 EXPORTS

Nothing is exported by default, but the functions can be requested in usual
C<Exporter> style,

    use Graph::DIMACS 'read_graph','write_graph';

=head1 SEE ALSO

L<Graph::Graph6>,

=head1 HOME PAGE

L<http://user42.tuxfamily.org/graph-graph6/index.html>

=head1 LICENSE

Copyright 2015, 2016, 2017 Kevin Ryde

Graph-Graph6 is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

Graph-Graph6 is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Graph-Graph6.  If not, see L<http://www.gnu.org/licenses/>.

=cut
