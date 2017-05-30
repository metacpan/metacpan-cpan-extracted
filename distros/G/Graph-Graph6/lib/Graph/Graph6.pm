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

package Graph::Graph6;
use 5.006;  # for 3-arg open
use strict;
use warnings;
use List::Util 'max';
use Carp 'croak';

use Exporter;
our @ISA = ('Exporter');
our @EXPORT_OK = ('read_graph','write_graph',
                  'HEADER_GRAPH6','HEADER_SPARSE6','HEADER_DIGRAPH6');

our $VERSION = 7;

# uncomment this to run the ### lines
# use Smart::Comments;


use constant HEADER_GRAPH6   => '>>graph6<<';
use constant HEADER_SPARSE6  => '>>sparse6<<';
use constant HEADER_DIGRAPH6 => '>>digraph6<<';

sub _read_header {
  my ($fh, $str) = @_;
  for (;;) {
    my $s2 = getc $fh;
    if (! defined $str) { return; }

    $str .= $s2;
    if ($str eq substr(HEADER_GRAPH6, 0, length($str))) {
      if (length($str) == length(HEADER_GRAPH6)) {
        ### header: $str
        # $format = 'graph6';
        return;
      }

    } elsif ($str eq substr(HEADER_SPARSE6, 0, length($str))) {
      if (length($str) == length(HEADER_SPARSE6)) {
        ### header: $str
        # $format = 'sparse6';
        return;
      }

    } elsif ($str eq substr(HEADER_DIGRAPH6, 0, length($str))) {
      if (length($str) == length(HEADER_DIGRAPH6)) {
        ### header: $str
        # $format = 'digraph6';
        return;
      }
    } else {
      return $str;
    }
  }
}

sub read_graph {
  my %options = @_;

  my $fh = $options{'fh'};
  if (defined $options{'str'}) {
    require IO::String;
    $fh = IO::String->new($options{'str'});
  }

  my $skip_newlines = 1;
  my $allow_header = 1;
  my $format = 'graph6';
  my $initial = 1;
  my $error;

  # Return: byte 0 to 63
  #      or -1 and $error=undef if end of file
  #      or -1 and $error=string if something bad
  my $read_byte = sub {
    for (;;) {
      my $str;
      my $len = read($fh, $str, 1);
      if (! defined $len) {
        $error = "Error reading: $!";
        return -1;
      }
      ### read byte: $str

      if ($skip_newlines && $str eq "\n") {
        # secret undocumented skipping of newlines, so skip blank lines
        # rather than reckoning one newline as immediate end of file
        ### skip initial newline ...
        next;
      }
      $skip_newlines = 0;

      if ($allow_header && $str eq '>') {
        $str = _read_header($fh, $str);
        if (defined $str) {
          $error = "Incomplete header: $str";
          return -1;
        }
        $allow_header = 0;
        next;
      }
      $allow_header = 0;

      my $n = ord($str) - 63;
      if ($n >= 0 && $n <= 63) {
        return $n;
      }

      if ($str eq '' || $str eq "\n") {
        ### end of file or end of line ...
        return -1;
      }

      if ($initial && $str eq '&') {
        $format = 'digraph6';
        ### $format
        $initial = 0;
        next;
      }
      if ($initial && $str eq ':') {
        $format = 'sparse6';
        ### $format
        $initial = 0;
        next;
      }
      if ($str eq "\r") {
        ### skip CR ...
        next;
      }

      $error = "Unrecognised character: $str";
      return -1;
    }
  };

  # Return: number 0 to 2^36-1
  #         -1 and $error=undef if end of file before any part of number
  #         -1 and $error if something bad, including partial number
  my $read_number = sub {
    my $n = $read_byte->();
    $initial = 0;
    if ($n <= 62) {
      return $n;
    }
    $n = $read_byte->();
    if ($n < 0) {
      $error ||= "Unexpected EOF";
      return -1;
    }
    my $len;
    if ($n <= 62) {
      $len = 2;
    } else {
      $n = 0;
      $len = 6;
    }
    foreach (1 .. $len) {
      my $n2 = $read_byte->();
      if ($n2 < 0) {
        $error ||= "Unexpected EOF";
        return -1;
      }
      $n = ($n << 6) + $n2;
    }
    return $n;
  };

  # Return true if good.
  # Return false and $error=string if something bad.
  # Return false and $error=undef if EOF.
  my $read = sub {

    if (! defined $fh) {
      if (defined(my $filename = $options{'filename'})) {
        open $fh, '<', $filename
          or do {
            $error = "Cannot open file $filename: $!";
            return;
          };
      }
    }

    my $num_vertices = $read_number->();
    ### $num_vertices

    if (my $format_func = $options{'format_func'}) {
      $format_func->($format);
    }
    if (my $format_ref = $options{'format_ref'}) {
      $$format_ref = $format;
    }

    if ($num_vertices < 0) {
      return;  # eof or possible error
    }
    if (my $num_vertices_func = $options{'num_vertices_func'}) {
      $num_vertices_func->($num_vertices);
    }
    if (my $num_vertices_ref = $options{'num_vertices_ref'}) {
      $$num_vertices_ref = $num_vertices;
    }

    my $edge_func = $options{'edge_func'};
    my $edge_aref = $options{'edge_aref'};
    if ($edge_aref) { @$edge_aref = (); }

    ### $format
    if ($format eq 'sparse6') {
      ### sparse6 ...
      my $v = 0;

      # number of bits required to represent $num_vertices - 1
      my $width = 0;
      while (($num_vertices-1) >> $width) { $width++; }

      my $bits = 0;
      my $n = 0;
      my $mask = (1 << $width) - 1;

      while ($v < $num_vertices) {
        if ($bits < 1) {
          $n = $read_byte->();
          if ($n < 0) {
            ### end n ...
            ### $error
            return ! defined $error;
          }
          $bits = 6;
        }
        $bits--;
        my $b = ($n >> $bits) & 1;   # first bit from $n
        $v += $b;   # propagate possible taintedness of $n,$b to $v
        ### $b
        ### to v: $v

        while ($bits < $width) {
          my $n2 = $read_byte->();
          if ($n2 < 0) {
            ### end n2 ...
            ### $error
            return ! defined $error;
          }
          $bits += 6;
          $n <<= 6;
          $n |= $n2;
        }
        $bits -= $width;
        my $x = ($n >> $bits) & $mask;
        ### $x

        if ($x > $v) {
          ### set v: $x
          $v = $x;
        } elsif ($v < $num_vertices) {  # padding can make v>n-1
          ### edge: "$x - $v"
          if ($edge_func) { $edge_func->($x, $v); }
          if ($edge_aref) { push @$edge_aref, [$x, $v]; }
        }
      }
      ### end ...

    } else {
      ### graph6 or digraph6 ...
      my $n;
      my $mask;
      my $from;
      my $to;
      my $output_edge = sub {
        if ($n & $mask) {
          my $taint0 = $n & 0;
          my $from_taint = $from + $taint0;
          my $to_taint   = $to   + $taint0;
          if ($edge_func) { $edge_func->(      $from_taint, $to_taint); }
          if ($edge_aref) { push @$edge_aref, [$from_taint, $to_taint]; }
        }
      };

      if ($format eq 'graph6') {
        # graph6 goes by columns of "to" within which "from" runs 0 though to-1
        # first column is to=1
        $from = 0;
        $to = 1;
        while ($to < $num_vertices) {
          if (($n = $read_byte->()) < 0) {
            $error ||= "Unexpected EOF";  # end of file is not ok
            return;
          }
          for ($mask = 1 << 5; $mask != 0; $mask >>= 1) {
            $output_edge->();
            $from++;
            if ($from >= $to) {
              $to++;
              last unless $to < $num_vertices;
              $from = 0;
            }
          }
        }
      } else {
        # graph6 goes by rows of "from", within which "to" runs 0 to n-1
        $from = 0;
        $to = 0;
        while ($from < $num_vertices) {
          if (($n = $read_byte->()) < 0) {
            $error ||= "Unexpected EOF";  # end of file is not ok
            return;
          }
          for ($mask = 1 << 5; $mask != 0; $mask >>= 1) {
            $output_edge->();
            $to++;
            if ($to >= $num_vertices) {
              $from++;
              last unless $from < $num_vertices;
              $to = 0;
            }
          }
        }
      }

      # read \n or \r\n, so can take successive graphs from file handle
      for (;;) {
        my $str;
        my $len = read($fh, $str, 1);
        if (! defined $len) {
          $error = "Error reading: $!";
          last;
        }
        if ($str eq "\r") {
          next;  # skip CR in case reading MS-DOS file as bytes
        }
        if ($str eq '' || $str eq "\n") {
          last;  # EOF or EOL, good
        }
      }
    }

    return 1;
  };


  if ($read->()) {
    return 1;  # successful read
  }
  if (defined $error) {
    ### $error
    my $error_func = $options{'error_func'} || \&Carp::croak;
    $error_func->($error);
    return undef;
  }
  return 0;  # EOF
}

#------------------------------------------------------------------------------

# For internal use.
# Biggest shift is by (6-1)*6 = 30 bits, so ok in 32-bit Perls circa 5.8 and
# earlier (where counts were taken modulo 32, not full value).
sub _number_to_string {
  my ($n) = @_;
  my $str;
  my $bitpos;
  if ($n > 258047) {  # binary 0b_111110_111111_111111 octal 0767777
    $str = '~~';
    $bitpos = (6-1)*6;
  } elsif ($n > 62) {
    $str = '~';
    $bitpos = (3-1)*6;
  } else {
    $str = '';
    $bitpos = 0;
  }
  for ( ; $bitpos >= 0; $bitpos -= 6) {     # big endian, high to low
    $str .= chr( (($n >> $bitpos) & 0x3F) + 63 );
  }
  return $str;
}

sub _edges_iterator_none {
  return;
}
sub _edge_predicate_none {
  return 0;
}

sub write_graph {
  my %options = @_;
  ### %options

  my $fh = $options{'fh'};
  if (! $fh
      && defined(my $str_ref = $options{'str_ref'})) {
    ### str_ref ...
    require IO::String;
    $fh = IO::String->new($$str_ref);
  }
  if (! $fh
      && defined(my $filename = $options{'filename'})) {
    ### $filename
    open $fh, '>', $filename
      or return 0;
  }

  my $format = $options{'format'};
  if (! defined $format) { $format = 'graph6'; }

  my $num_vertices = $options{'num_vertices'};
  if (! defined $num_vertices
      && (my $edge_aref = $options{'edge_aref'})) {
    # from maximum in edge_aref
    $num_vertices = -1;
    foreach my $edge (@$edge_aref) {
      $num_vertices = max($num_vertices, @$edge);
    }
    $num_vertices += 1;
  }
  if (! defined $num_vertices) {
    croak 'Missing num_vertices';
  }
  ### $num_vertices

  print $fh
    ($options{'header'} ? ">>$format<<" : ()),
    ($format eq 'sparse6' ? ':'
     : $format eq 'digraph6' ? '&'
     : ()),
       _number_to_string($num_vertices)
       or return 0;

  my $bitpos = 5;
  my $word = 0;
  my $put_bit = sub {
    my ($bit) = @_;
    $word |= $bit << $bitpos;
    if ($bitpos > 0) {
      $bitpos--;
    } else {
      print $fh chr($word + 63) or return 0;
      $bitpos = 5;
      $word = 0;
    }
    return 1;
  };

  if ($format eq 'sparse6') {
    my $edge_iterator;

    if (my $edge_aref = $options{'edge_aref'}) {
      ### edge_aref ...
      # swap to [from <= to]
      my @edges = map { $_->[0] > $_->[1]
                          ? [ $_->[1], $_->[0] ]
                          : $_
                        } @$edge_aref;
      # sort to ascending "to", and within those ascending "from"
      @edges = sort { ($a->[1] <=> $b->[1]) || ($a->[0] <=> $b->[0]) } @edges;
      $edge_iterator = sub {
        return @{(shift @edges) || []};
      };
    }

    if (! $edge_iterator
        && (my $edge_predicate = $options{'edge_predicate'})) {
      ### edge_predicate ...
      my $from = 0;
      my $to = -1;
      $edge_iterator = sub {
        for (;;) {
          $from++;
          if ($from > $to) {
            $to++;
            if ($to >= $num_vertices) {
              return;
            }
            $from = 0;
          }
          if ($edge_predicate->($from,$to)) {
            return ($from,$to);
          }
        }
      };
    }

    $edge_iterator ||= \&_edges_iterator_none;

    # $width = number of bits required to represent $num_vertices - 1
    my $width = 0;
    if ($num_vertices > 0) {
      while (($num_vertices-1) >> $width) { $width++; }
    }
    ### $width

    my $put_n = sub {
      my ($n) = @_;
      for (my $i = $width-1; $i >= 0; $i--) {
        $put_bit->(($n >> $i) & 1) or return 0;
      }
      return 1;
    };

    my $v = 0;
    while (my ($from, $to) = $edge_iterator->()) {
      ### edge: "$from $to"

      if ($to == $v + 1) {
        ### increment v ...
        $put_bit->(1) or return 0;

      } else {
        if ($to != $v) {   # $to >= $v+2
          ### set v ...
          ($put_bit->(1)   # set v done with b[i]=1
           && $put_n->($to))
            or return 0;
        }
        $put_bit->(0) or return 0;     # v unchanged
      }
      ### write: $from
      $put_n->($from) or return 0;     # edge ($from, $v)

      $v = $to;
    }

    if ($bitpos != 5) {
      ### pad: $bitpos+1
      ### $v

      # Rule for padding so not to look like self-loop n-1 to n-1.
      # There are $bitpos+1 many bits to pad.
      # b[i]=0 bit if num_vertices = 2,4,8,16 so width=1,2,3,4
      #               and pad >= width+1
      #               and edge involving n-2 so final v=n-2
      # 0 111 is set v=n-1 provided prev <= n-2
      # 1 111 is a v+1 and edge n-1,v which is n-1,n out of range
      if (($width >= 1 && $width <= 4)
          && $num_vertices == (1 << $width)    # 1,2,4,8
          && $bitpos >= $width                 # room for final b[i] and x[i]
          && $v == $num_vertices - 2) {
        ### pad 0 ...
        $put_bit->(0) or return 0;
      }

      ### pad with 1s: $bitpos
      until ($bitpos == 5) {
        $put_bit->(1) or return 0;
      }
    }

  } else {
    my $edge_predicate = $options{'edge_predicate'};

    if (! $edge_predicate
        && (my $edge_aref = $options{'edge_aref'})) {
      ### edge_predicate from edge_aref ...
      my %edge_hash;
      foreach my $edge (@$edge_aref) {
        my ($from, $to) = @$edge;
        if ($from > $to && $format eq 'graph6') { ($from,$to) = ($to,$from); }
        $edge_hash{$from}->{$to} = undef;
      }
      $edge_predicate = sub {
        my ($from, $to) = @_;
        return exists $edge_hash{$from}->{$to};
      };
    }

    $edge_predicate ||= \&_edge_predicate_none;

    if ($format eq 'graph6') {
      foreach my $to (1 .. $num_vertices-1) {
        foreach my $from (0 .. $to-1) {
          $put_bit->($edge_predicate->($from,$to) ? 1 : 0) or return 0;
        }
      }
    } elsif ($format eq 'digraph6') {
      foreach my $from (0 .. $num_vertices-1) {
        foreach my $to (0 .. $num_vertices-1) {
          $put_bit->($edge_predicate->($from,$to) ? 1 : 0) or return 0;
        }
      }
    } else {
      croak 'Unrecognised format: ',$format;
    }

    until ($bitpos == 5) {
      $put_bit->(0) or return 0;
    }
  }

  print $fh "\n" or return 0;
  return 1;
}

    # if (! $edge_predicate
    #     && (my $edge_matrix = $options{'edge_matrix'})) {
    #   $edge_predicate = sub {
    #     my ($from, $to) = @_;
    #     return $edge_matrix->[$from]->[$to];
    #   };
    # }

1;
__END__

=for stopwords Ryde undirected multi-edges arrayref nauty tty

=head1 NAME

Graph::Graph6 - read and write graph6, sparse6, digraph6 format graphs

=head1 SYNOPSIS

 use Graph::Graph6;
 my ($num_vertices, @edges);
 Graph::Graph6::read_graph(filename         => 'foo.g6',
                           num_vertices_ref => \$num_vertices,
                           edge_aref        => \@edges);

 Graph::Graph6::write_graph(filename     => 'bar.s6',
                            format       => 'sparse6',
                            num_vertices => $num_vertices,
                            edge_aref    => \@edges);

=head1 DESCRIPTION

This module reads and writes graph6, sparse6 and digraph6 files.  These file
formats are per

=over 4

L<http://cs.anu.edu.au/~bdm/data/formats.txt>

=back

These formats represent a graph (a graph theory graph) with vertices
numbered 0 to n-1 encoded into printable ASCII characters in the range C<?>
to C<~>.  The maximum number of vertices is 2^36-1.

graph6 and sparse6 represent an undirected graph.  graph6 is an upper
triangle adjacency matrix of bits.  Its encoding is 6 bits per character so
N vertices is a file size roughly N^2/12 bytes.  sparse6 lists edges as
pairs of vertices i,j and is good for graphs with relatively few edges.
sparse6 can have multi-edges and self loops.  graph6 cannot.

digraph6 represents a directed graph as an NxN adjacency matrix encoded 6
bits per character so a file size roughly N^2/6 bytes.  It can include self
loops.

=cut

# GP-DEFINE  graph6_size_bits_by_sum(n) = sum(j=1,n-1, sum(i=0, j-1, 1));
# GP-DEFINE  graph6_size_bits_formula(n) = n*(n-1)/2;
# GP-Test  vector(100,n, graph6_size_bits_formula(n)) == \
# GP-Test  vector(100,n, graph6_size_bits_by_sum(n))

# GP-DEFINE  graph6_size_bits_formula(n) = n^2/2 - n/2;
# GP-Test  vector(100,n, graph6_size_bits_formula(n)) == \
# GP-Test  vector(100,n, graph6_size_bits_by_sum(n))

=pod

This module reads and writes in a "native" way as integer vertex numbers 0
to n-1.  See L</SEE ALSO> below for C<Graph.pm>, C<Graph::Easy> and
C<GraphViz2> interfaces.

These formats are used by the Nauty tools

=over

L<http://cs.anu.edu.au/~bdm/nauty> and 
L<http://pallini.di.uniroma1.it>

=back

as output for generated graphs and input for calculations of automorphism
groups, canonicalizing, and more.  The House of Graphs
L<http://hog.grinvin.org> takes graph6 for searches and uploads and includes
it among download formats.

=head1 FUNCTIONS

=head2 Reading

=over

=item C<$success = Graph::Graph6::read_graph(key =E<gt> value, ...)>

Read graph6, sparse6 or digraph6.  The key/value options are

    filename           => filename (string)
    fh                 => filehandle (glob ref)
    str                => string
    num_vertices_ref   => scalar ref
    num_vertices_func  => coderef
    edge_aref          => array ref
    edge_func          => coderef
    error_func         => coderef

The return value is

    1         if graph successfully read
    0         if end of file (no graph)
    croak()   if invalid content or file error
    undef     if error_func returns instead of dying

C<filename>, C<fh> or C<str> is the input.  The output is the number of
vertices and a list of edges.

The number of vertices n is stored to C<num_vertices_ref> or call to
C<num_vertices_func>, or both.

    $$num_vertices_ref = $n;
    $num_vertices_func->($n);

Each edge is stored into C<edge_aref> or call to C<edge_func>, or both.  Any
existing contents of C<edge_aref> array are deleted.  C<$from> and C<$to>
are integers in the range 0 to n-1.  graph6 has C<$from E<lt> $to>.  sparse6
has C<$from E<lt>= $to>.  digraph6 has any values.  For sparse6, multi-edges
give multiple elements stored and multiple calls made.

    push @$edge_aref, [ $from, $to ];   # (and emptied first)
    $edge_func->($from, $to);

C<error_func> is called for any file error or invalid content.

    $error_func->($str, $str, ...);

The default C<error_func> is C<croak()>.  If C<error_func> returns then the
return from C<read_graph()> is C<undef>.

An immediate end of file gives the end of file return 0.  It's common to
have multiple graphs in a file, one per line and possibly an empty file if
no graphs of some kind.  They can be read successively with C<read_graph()>
until 0 at end of file.

End of file is usually only of interest when reading an C<fh> handle.  But
empty file or empty input string give the end of file return too.  This is
designed to make the input sources equivalent (C<filename> is the same as
open and C<fh>, and either the same as slurp and pass C<str>).

For C<num_vertices_ref> and C<edge_aref>, a C<my> can be included in the
ref-taking in the usual way if desired,

    # "my" included in refs
    read_graph(filename         => 'foo.g6',
               num_vertices_ref => \my $num_vertices,
               edge_aref        => \my @edges);

This is compact and is similar to the common C<open my $fh, ...> declaring
an output variable in the call which is its first use.

graph6 has edges ordered by increasing C<$to> and within that increasing
C<$from>.  sparse6 normally likewise, but the format potentially allows
C<$from> to jump around.  digraph6 has edges ordered by increasing C<$from>
and within that increasing C<$to>.  But the suggestion is not to rely on
edge order (only on C<$from E<lt>= $to> for graph6 and sparse6 noted above).

In C<perl -T> taint mode, C<$num_vertices> and edge C<$from,$to> outputs are
tainted in the usual way for reading from a file, a tainted C<str>, or an
C<fh> handle of a file or tie of something tainted.

=back

=head2 Writing

=over

=item C<$ret = Graph::Graph6::write_graph(key =E<gt> value, ...)>

Write graph6 or sparse6.  The key/value options are

    filename           => filename (string)
    fh                 => filehandle (glob ref)
    str_ref            => output string (string ref)
    format             => "graph6", "sparse6", "digraph6"
                             (string, default "graph6")
    header             => boolean (default false)
    num_vertices       => integer
    edge_aref          => array ref
    edge_predicate     => coderef

The return value is

    1       if graph successfully written
    0       if some write error, error in $!

C<filename>, C<fh> or C<str_ref> is the output destination.  C<str_ref> is a
scalar ref to store to, so for example

    my $str;
    write_graph(str_ref => \$str, ...)

    # or
    write_graph(str_ref => \my $str, ...)

C<format> defaults to the dense C<"graph6">, or can be C<"sparse6"> or
C<"digraph6">

    write_graph(format => "sparse6", ...)

C<header> flag writes an initial C<"E<gt>E<gt>graph6E<lt>E<lt>">,
C<"E<gt>E<gt>sparse6E<lt>E<lt>"> or C<"E<gt>E<gt>digraph6E<lt>E<lt>"> as
appropriate.  This is optional for the nauty programs and for
C<read_graph()> above, but may help a human reader distinguish a graph from
tty line noise.

C<num_vertices> is mandatory, except if C<edge_aref> is given then the
default is from the maximum vertex number there (which is convenient as long
as the maximum vertex has at least one edge).  Must have C<num_vertices <
2**36>.

C<edge_aref> is an arrayref of edges which are in turn arrayref pairs of
integers C<[$from,$to]>.  They can be in any order but all must be integers
in the range 0 to <$num_vertices-1> inclusive.  For graph6 and sparse6
(being undirected) the C<$from,$to> pairs can be either way around.  graph6
ignores self-loops and writes duplicates just once each.  sparse6 can have
self-loops and repeated entries for multi-edges.  digraph6 can have
self-loops but writes all duplicates just once each.

    edge_aref => [ [5,6], [0,1] ]    # edges in any order
    edge_aref => [ [5,4] ]      # pairs either way for undirected

C<edge_predicate> is another way to specify edges.  It is called with
integers C<$from,$to> to test whether such an edge exists.  graph6 has
C<$from E<lt> $to>.  sparse6 has C<$from E<lt>= $to>.  digraph6 has any.
digraph6 and sparse6 self-loops can be written this way, but not sparse6
multi-edges.

    $bool = $edge_predicate->($from, $to);    # $from <= $to

C<edge_predicate> is preferred for writing graph6 and digraph6.
C<edge_aref> is preferred for writing sparse6.  But whichever you give is
used for any format.

The output includes a final newline C<"\n"> so graphs can be written to a
file handle one after the other.

=back

=head2 Other

=over

=item C<$str = Graph::Graph6::HEADER_GRAPH6 ()>

=item C<$str = Graph::Graph6::HEADER_SPARSE6 ()>

=item C<$str = Graph::Graph6::HEADER_DIGRAPH6 ()>

Return the header strings C<E<gt>E<gt>graph6E<lt>E<lt>>,
C<E<gt>E<gt>sparse6E<lt>E<lt>> or C<E<gt>E<gt>digraph6E<lt>E<lt>>.

=back

=head1 EXPORTS

Nothing is exported by default, but the functions can be requested in usual
C<Exporter> style,

    use Graph::Graph6 'read_graph','write_graph';

=head1 SEE ALSO

L<Graph::Reader::Graph6>,
L<Graph::Writer::Graph6>,
L<Graph::Writer::Sparse6>

L<Graph::Easy::Parser::Graph6>,
L<Graph::Easy::As_graph6>,
L<Graph::Easy::As_sparse6>

L<GraphViz2::Parse::Graph6>

L<Carp>

L<nauty-showg(1)>, L<nauty-copyg(1)>

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


# Other possibilities:
#   str_ref
#   str_ref_successively    going from pos() and setting pos()
#
