# Copyright 2021 Kevin Ryde
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

package Graph::Maker::HanoiExchange;
use 5.004;
use strict;
use Carp 'croak';
use Graph::Maker;

use vars '$VERSION','@ISA';
$VERSION = 18;
@ISA = ('Graph::Maker');

# uncomment this to run the ### lines
# use Smart::Comments;


sub _default_graph_maker {
  require Graph;
  Graph->new(@_);
}

sub _vertex_names_func_digits {
  my ($digits, $spindles) = @_;
  return join('', reverse @$digits);
}
sub _vertex_names_func_integer {
  my ($digits, $spindles) = @_;
  my $ret = 0;
  foreach my $digit (reverse @$digits) {  # digits high to low
    $ret = $ret*$spindles + $digit;
  }
  return $ret;
}

sub init {
  my ($self, %params) = @_;
  ### HanoiExchange init: %params

  my $discs     = delete($params{'discs'})     || 0;
  my $spindles  = delete($params{'spindles'})  || 3;
  my $graph_maker = delete($params{'graph_maker'}) || \&_default_graph_maker;

  # this not documented yet ...
  my $vertex_names = delete($params{'vertex_names'}) || 'integer';
  my $vertex_name_func = $self->can("_vertex_names_func_$vertex_names")
    || croak "Unrecognised vertex_names: ",$vertex_names;

  my $graph = $graph_maker->(%params);

  $graph->set_graph_attribute
    (name =>
     "Hanoi Exchange $discs"
     . ($spindles == 3 ? '' : " Discs, $spindles Spindles"));

  # $t[$d] is the spindle number (0 .. $spindles-1) which holds disc $d.
  # $d = 0 is the smallest disc.
  my @t = (0) x $discs;
  my $add_edge = ($graph->is_directed ? 'add_cycle' : 'add_edge');
 T: for (;;) {
    my $v = $vertex_name_func->(\@t, $spindles);
    $graph->add_vertex($vertex_name_func->(\@t, $spindles));
    ### from: "v= ".join(',',@t)

    # Smallest disc moves anywhere, other than its current spindle.
    # To smaller spindle number so no duplicate edges.
    my @t2;
    if ($discs) {
      @t2 = @t;
      foreach my $to_digit (0 .. $t[0]-1) {
        $t2[0] = $to_digit;
        my $v2 = $vertex_name_func->(\@t2, $spindles);
        $graph->$add_edge($v, $v2);
        ### smallest move: "$t[0] to $t2[0]  edge $v -- $v2"
      }
    }

    # $seen[$spindle] true when $spindle has one of the 0 .. $d-1 discs
    my @seen;
    foreach my $d (1 .. $#t) {    # disc number
      next if $seen[$t[$d-1]]++;  # $d-1 not on top of its spindle
      next if $seen[$t[$d]];      # $d not on top of its spindle
      next unless $t[$d-1] < $t[$d];  # one way so no duplicate edges
      @t2 = @t;
      ($t2[$d],$t2[$d-1]) = ($t2[$d-1],$t2[$d]);    # exchange $d, $d-1
      my $v2 = $vertex_name_func->(\@t2, $spindles);
      $graph->$add_edge($v, $v2);
      ### exchange: "pos=$d to vec ".join(',',@t2)."  edge $v -- $v2"
    }
    ### final seen: @seen

    # increment t vector ...
    foreach my $pos (0 .. $#t) {
      next T if ++$t[$pos] < $spindles;
      $t[$pos] = 0;
    }
    last; # no more @t configurations
  }
  return $graph;
}

Graph::Maker->add_factory_type('hanoi_exchange' => __PACKAGE__);
1;

__END__

=for stopwords Ryde eg subgraphs Stockmeyer undirected et al OEIS

=head1 NAME

Graph::Maker::HanoiExchange - create towers of Hanoi exchanging discs graph

=for test_synopsis my ($graph)

=head1 SYNOPSIS

 use Graph::Maker::HanoiExchange;
 $graph = Graph::Maker->new ('hanoi_exchange', discs => 3);

=head1 DESCRIPTION

C<Graph::Maker::Hanoi> creates a C<Graph.pm> graph of configurations of
discs on spindles in a variation on the towers of Hanoi puzzle where pairs
of discs exchange.

=over

R. S. Scorer, P. M. Grundy and C. A. B. Smith, "Some Binary Games",
The Mathematical Gazette, July 1944, volume 28, number 280, pages 96-103,
L<http://www.jstor.org/stable/3606393>, section 4(iii) Plane Network Game.

=back

      0  discs=>0         0                     0
                         / \  discs=>2         / \    discs=>3
                        1---2                 1---2
      0  discs=>1      /     \               /     \
     / \              7       5             3       6
    1---2            / \     / \           / \     / \
                    8---6---3---4         4---5---7---8
                                             /     \
                                        9   /       \   18
                                       / \ /         \ / \
                                     10--11           19--20
                                     /     \         /     \
                                   12      15-------21      24
                                   / \     / \     / \     / \
                                 13--14--16--17   22--23--25--26

The puzzle has N discs and 3 spindles.  The discs on a spindle are stacked
in size order, smallest at the top.  Each graph vertex is a configuration of
discs on spindles.  Each graph edge is a legal step from one configuration
to another.  In the variation here, these are:

=over

=item

Smallest disc moves to any other spindle.

=item

Two discs exchange when they differ in size by 1, are on different spindles,
and each is top-most on its spindle.

=back

A configuration has up to 4 possible steps (vertex degrees E<lt>= 4).  The
maximum is when the smallest, 2nd smallest, and 3rd smallest, are the tops
of the 3 spindles.  The smallest moves to 2 places, the smallest and 2nd
exchange, and the 2nd and 3rd exchange.  For example vertex 5 in the discs=3
example above.

Vertex names are integers 0 to 3^N-1.  Each ternary digit is a disc and its
value 0,1,2 is which spindle holds that disc.  The least significant digit
is the smallest disc.  The edges are then to change the least significant
digit to another value; or exchange two adjacent digits provided neither
occurs anywhere below its position (which also requires they're two
different digit values).

For discs E<lt>= 1 the graph is the same as the plain Hanoi.  For discs=2
the graph is isomorphic, but the vertex names are not the same.  For discs
E<gt>= 3 the graph is different from the plain Hanoi, essentially since
cross connections between subgraphs are from inner-most points like 5--11 in
the example above.

=cut

# The largest disc can move only when it and the second largest are alone on
# their spindles.  For example in the discs=3 example above, 5 to 11 (ternary
# 012 to 102, exchange high two digits).  For discs=4, vertex 17 (ternary
# 0122) will be the next corresponding connection point.

=pod

=head2 Spindles

Option C<spindles =E<gt> S> specifies how many spindles are used for the
puzzle.  The default is 3 as described above.  For S spindles and N discs,
the vertices are numbered 0 to S^N-1 inclusive and each digit in base S is
which spindle holds the disc.

Discs=1 is always a complete-S since the single disc can move from anywhere
to anywhere.

Discs E<gt>= 2 has complete-S sub-graphs which are the small disc moving
around on some configuration of the bigger discs.  Connections between those
subgraphs are exchanges (including exchanges of the smallest and second
smallest).

Spindles=1 is allowed but is a trivial 1-vertex graph since all discs are on
that spindle and no moves are possible.

Spindles=2 is allowed but is 2^N vertices in path-4 subgraphs since only the
smallest and 2nd smallest discs can ever move.

=head1 FUNCTIONS

=over

=item C<$graph = Graph::Maker-E<gt>new('hanoi_exchange', key =E<gt> value, ...)>

The key/value parameters are

    discs     =>  integer
    spindles  =>  integer, default 3
    graph_maker => subr(key=>value) constructor, default Graph->new

Other parameters are passed to the constructor, either C<graph_maker> or
C<Graph-E<gt>new()>.

If the graph is directed (the default) then edges are added both forward and
backward between vertices.  Option C<undirected =E<gt> 1> creates an
undirected graph and for it there is a single edge between vertices.

=back

=head1 FORMULAS

=head2 Solution Length and Diameter

The path length between corner vertices, which is the solution moving N
discs from one spindle to another, is calculated and shown to be the graph
diameter by

=over

Paul K. Stockmeyer et al, "Exchanging Disks in the Tower of Hanoi",
International Journal of Computer Mathematics, volume 59, number 1-2, pages
37-47, 1995.  L<http://www.cs.wm.edu/~pkstoc/gov.pdf>.  See f(n) in
section 3.

=back

as recurrence

    f(N) = f(N-1) + f(N-2) + 2*f(N-4) + 3    for N>=4
         = 0, 1, 3, 7, 13, 25, 47, 89, 165, ...

This grows as a power r^N where r = 1.853... is the largest root of x^4 -
x^3 - x^2 - 2.  (Smaller than the plain Hanoi 2^N - 1.)

They consider also the geometric distance in a layout such as drawn above.
The resulting distance grows as 7/2*2^N.

=head1 OEIS

Entries in Sloane's Online Encyclopedia of Integer Sequences related to
this tree include

=over

L<http://oeis.org/A341579> (etc)

=back

    A341579    diameter

=cut

# GP-DEFINE  read("my-oeis.gp");
# vector(10,n,f(n))
# not in OEIS: 1, 3, 7, 13, 25, 47, 89, 165, 307, 569
# abs(polroots(polrecip(1 - x - x^2 - 2*x^4)))
# not in OEIS: 1.8535602775

#------
# GP-DEFINE  read("memoize.gp");
# GP-DEFINE  f(n) = {
# GP-DEFINE    n>=0 || error();
# GP-DEFINE    if(n==0,0, n==1,1, n==2,3, n==3,7,
# GP-DEFINE       f(n-1) + f(n-2) + 2*f(n-4) + 3);
# GP-DEFINE  }
# GP-DEFINE  f=memoize(f);
# GP-DEFINE  A341579(n) = f(n);
# GP-DEFINE  gf(x) = (x + x^2 + x^3)/(1 - 2*x + x^3 - 2*x^4 + 2*x^5);
# GP-DEFINE  f_poly(x) = x^5 - 2*x^4 + x^2 - 2*x + 2;  \\ charpoly of f
# GP-Test  f_poly(x) == polrecip(denominator(gf(x)))
#
# GP-Test  my(want=OEIS_samples("A341579")); /* OFFSET=0 */ \
# GP-Test    vector(#want,n,n--; A341579(n)) == want
# GP-Test  my(want=OEIS_bfile_samples("A341579")); /* OFFSET=0 */ \
# GP-Test    print("b341579  ",#want); \
# GP-Test    vector(#want,n,n--; A341579(n)) == want
#
# GP-Test-Last  /* Stockmeyer et al, f in terms of g equation (1) */ \
# GP-Test-Last  vector(100,n, f(n)) == \
# GP-Test-Last  vector(100,n, 2*g(n-1) + 1)
# GP-Test-Last  my(a=A341579); \
# GP-Test-Last  vector(100,n, a(n)) == \
# GP-Test-Last  vector(100,n, 2*A341580(n-1) + 1)
#
# GP-Test  /* Stockmeyer et al, and formula above */ \
# GP-Test  my(a=f); \
# GP-Test  vector(100,n,n+=3; a(n)) == \
# GP-Test  vector(100,n,n+=3; a(n-1) + a(n-2) + 2*a(n-4) + 3)
# GP-Test  vector(100,N,N+=3; f(N) == f(N-1) + f(N-2) + 2*f(N-4) + 3) == \
# GP-Test  vector(100,N,N+=3; 1)
#
# GP-Test  /* f full recurrence */ \
# GP-Test  my(a=f); \
# GP-Test  vector(100,n,n+=4; a(n)) == \
# GP-Test  vector(100,n,n+=4; 2*a(n-1) - a(n-3) + 2*a(n-4) - 2*a(n-5))
#
# GP-Test  gf(x) + O(x^100) == sum(n=0,100, f(n)*x^n)
# GP-Test  gf(x) == x*(1 + x + x^2) / ( (1-x) * (1 - x - x^2 - 2*x^4) )
# GP-Test  gf(x) == -1/(1-x) + (1 + x + x^2 + 2*x^3)/(1 - x - x^2 - 2*x^4)
#
# GP-Test  /* example */ \
# GP-Test  f(3) == 7
# GP-Test-Last  A341580(2) == 3
#
# GP-DEFINE  my(p=Mod('x,'x^4-'x^3-'x^2-2)); f_compact(n) = subst(lift(p^n),'x,2) - 1;
# GP-Test  vector(200,n,n--; f(n)) == \
# GP-Test  vector(200,n,n--; f_compact(n))

# f backwards: -5/4, -1, -1/2, 0, 0, 1, 3, 7, 13
# g backwards: -3/4, -1/2, -1/2, 0, 1, 3, 6
# d backwards: -1/2, -1/4, 0, 0, 1, 3, 8, 18
# vector(20,n,f(n))
# vector(20,n,n-=6; d_compact(n) - 7/2<<n)
# vector(20,n,(f(n)+1)/2)
# OEIS_recurrence_guess(vector(20,n,n--;f(n)))
# for(n=0,35,print1(f(n),",");if(n==18||n==28,print()))
# my(p=Mod(x,x^4 - x^3 - x^2 - 2)); \
# lindep([vector(20,n,n+=10;  2*d(n) - 7<<n), \
#         vector(20,n,n+=10;polcoeff(lift(p^n),3)),\
#         vector(20,n,n+=10;polcoeff(lift(x*p^n),3)),\
#         vector(20,n,n+=10;polcoeff(lift(x^2*p^n),3)),\
#         vector(20,n,n+=10;polcoeff(lift(x^3*p^n),3))])
# lindep([vector(20,n,n+=10; n-=2; d(n)*2 - 7<<n), \
#         vector(20,n,n+=10;polcoeff(lift(p^n),0)),\
#         vector(20,n,n+=10;polcoeff(lift(p^n),1)),\
#         vector(20,n,n+=10;polcoeff(lift(p^n),2)),\
#         vector(20,n,n+=10;polcoeff(lift(p^n),3))])

#------
# GP-DEFINE  \\ g = half of f
# GP-DEFINE  g(n) = n>=0 || error(); (f(n+1)-1)/2;
# GP-DEFINE  A341580(n) = g(n);
# GP-DEFINE  gg(x) = (gf(x)/x - 1/(1-x))/2;
# vector(20,n,n--; g(n))
# not in OEIS: 1, 3, 6, 12, 23, 44, 82, 153, 284, 528, 979, 1816, 3366
# OEIS_recurrence_guess(vector(20,n,n--;g(n)))
# for(n=0,35,print1(g(n),",");if(n==18||n==28,print()))
#
# GP-Test  my(want=OEIS_samples("A341580")); /* OFFSET=0 */ \
# GP-Test    vector(#want,n,n--; A341580(n)) == want
# GP-Test  my(want=OEIS_bfile_samples("A341580")); /* OFFSET=0 */ \
# GP-Test    print("b341580  ",#want); \
# GP-Test    vector(#want,n,n--; A341580(n)) == want
#
# GP-Test-Last  /* Stockmeyer et al, g in terms of h equation (2) */ \
# GP-Test-Last  vector(100,n, g(n)) == \
# GP-Test-Last  vector(100,n, g(n-1) + h(n-1) + 1)
# GP-Test-Last  my(a=A341580); \
# GP-Test-Last  vector(100,n, a(n)) == \
# GP-Test-Last  vector(100,n, a(n-1) + A341581(n-1) + 1)
#
# GP-Test  /* g same full recurrence as f */ \
# GP-Test  my(a=g); \
# GP-Test  vector(100,n,n+=4; a(n)) == \
# GP-Test  vector(100,n,n+=4; 2*a(n-1) - a(n-3) + 2*a(n-4) - 2*a(n-5))
#
# GP-Test  gg(x) + O(x^100) == sum(n=0,100, g(n)*x^n)
# GP-Test  gg(x) == x * (1 + x + x^3) /( (1-x) * (1 - x - x^2 - 2*x^4) )
# GP-Test  gg(x) == -1/(1-x) + (1 + x + x^2 + x^3)/(1 - x - x^2 - 2*x^4)
#
# GP-Test  /* example */ \
# GP-Test  g(2) == 3
# GP-Test  g(3) == 6
# GP-Test-Last  A341581(2) == 2
#
# GP-DEFINE  my(p=Mod('x,'x^4-'x^3-'x^2-2)); g_compact(n) = subst(lift(p^(n+1)),'x,2)/2 - 1;
# GP-Test  vector(200,n,n--; g(n)) == \
# GP-Test  vector(200,n,n--; g_compact(n))


#------
# GP-DEFINE  h(n) = n>=0 || error(); if(n==0,0,n==1,1, f(n-2) + g(n-1) + 1);
# GP-DEFINE  A341581(n) = h(n);
# GP-DEFINE  gh(x) = (x + x^3 + x^4)/(1 - 2*x + x^3 - 2*x^4 + 2*x^5);
# GP-Test  h(0) == 0
# GP-Test  h(1) == 1
# vector(12,n,n--; h(n))
# not in OEIS: 1, 2, 5, 10, 20, 37, 70, 130, 243, 450, 836
# OEIS_recurrence_guess(vector(20,n,n--;h(n)))
# for(n=0,35,print1(h(n),",");if(n==18||n==28,print()))
#
# GP-Test  my(want=OEIS_samples("A341581")); /* OFFSET=0 */ \
# GP-Test    vector(#want,n,n--; A341581(n)) == want
# GP-Test  my(want=OEIS_bfile_samples("A341581")); /* OFFSET=0 */ \
# GP-Test    print("b341581  ",#want); \
# GP-Test    vector(#want,n,n--; A341581(n)) == want
#
# GP-Test  /* Stockmeyer et al, g in terms of h equation (2) */ \
# GP-Test  vector(20,n,n++; h(n)) == \
# GP-Test  vector(20,n,n++; f(n-2) + g(n-1) + 1)
# GP-Test  my(a=A341581); \
# GP-Test  vector(20,n,n++; a(n)) == \
# GP-Test  vector(20,n,n++; A341579(n-2) + A341580(n-1) + 1)
#
# GP-Test  /* h same full recurrence as f */ \
# GP-Test  my(a=h); \
# GP-Test  vector(100,n,n+=4; a(n)) == \
# GP-Test  vector(100,n,n+=4; 2*a(n-1) - a(n-3) + 2*a(n-4) - 2*a(n-5))
#
# GP-Test  gh(x) + O(x^100) == sum(n=0,100, h(n)*x^n)
# GP-Test  gh(x) == x * (1 + x^2 + x^3) /( (1-x) * (1 - x - x^2 - 2*x^4) )
# GP-Test  gh(x) == -1/(1-x) + (1 + x + x^3)/(1 - x - x^2 - 2*x^4)
#
# GP-Test  /* example */ \
# GP-Test  h(3) == 5
# GP-Test  A341580(2) == 3
# GP-Test  A341579(1) == 1
#
# GP-DEFINE  my(p=Mod('x,'x^4-'x^3-'x^2-2)); h_compact(n) = subst(lift(p^(n+2))\'x,'x,2)/2 - 1;
# GP-Test  vector(200,n,n--; h(n)) == \
# GP-Test  vector(200,n,n--; h_compact(n))

#------
# GP-DEFINE  \\ simple moves of the smallest disc (not exchanges)
# GP-DEFINE  fmoves(n) = n>=0 || error(); if(n==0,0, f(n) - f(n-1));
# GP-DEFINE  A341582(n) = fmoves(n);
# GP-DEFINE  gfmoves(x) = (x + x^2 + x^3)/(1 - x - x^2 - 2*x^4);
# OEIS_recurrence_guess(vector(100,n,n--;fmoves(n)))
# vector(10,n, fmoves(n))
# not in OEIS: 1, 2, 4, 6, 12, 22, 42, 76, 142, 262
# vector(10,n, g(n))
#
# GP-Test  my(want=OEIS_samples("A341582")); /* OFFSET=0 */ \
# GP-Test    vector(#want,n,n--; A341582(n)) == want
# GP-Test  my(want=OEIS_bfile_samples("A341582")); /* OFFSET=0 */ \
# GP-Test    print("b341582  ",#want); \
# GP-Test    vector(#want,n,n--; A341582(n)) == want
#
# GP-Test  /* diffs of f */ \
# GP-Test  my(a=fmoves); \
# GP-Test  vector(100,n, a(n)) == \
# GP-Test  vector(100,n, A341579(n) - A341579(n-1))
#
# GP-Test  /* fmoves full recurrence */ \
# GP-Test  my(a=fmoves); \
# GP-Test  vector(100,n,n+=4; a(n)) == \
# GP-Test  vector(100,n,n+=4; a(n-1) + a(n-2) + 2*a(n-4))
#
# GP-Test  polisirreducible(1 - x - x^2 - 2*x^4)
# GP-Test  gfmoves(x) == x*(1 + x + x^2)/(1 - x - x^2 - 2*x^4)
#
# GP-DEFINE  my(p=Mod('x,'x^4-'x^3-'x^2-2)); fmoves_compact(n) = subst(lift(p^n)\'x,'x,2);
# GP-Test  vector(200,n,n--; fmoves(n)) == \
# GP-Test  vector(200,n,n--; fmoves_compact(n))

#------
# GP-DEFINE  nearly_equal_epsilon = 1e-15;
# GP-DEFINE  nearly_equal(x,y, epsilon=nearly_equal_epsilon) = {
# GP-DEFINE    \\ print(type(x)," ",type(y)," ",x," ",y);
# GP-DEFINE    my(d=x-y); \\ ensure compatible types
# GP-DEFINE    if(type(x)=="t_MAT",x=Vec(x);y=Vec(y));
# GP-DEFINE    if(type(x)=="t_VEC" || type(x)=="t_COL",
# GP-DEFINE         sum(i=1,max(#x,#y), !nearly_equal(x[i],y[i],epsilon)) == 0,
# GP-DEFINE       type(x)=="t_QUAD" || type(x)=="t_COMPLEX",
# GP-DEFINE            nearly_equal(real(x-y),0,epsilon)
# GP-DEFINE         && nearly_equal(imag(x-y),0,epsilon),
# GP-DEFINE       abs(d) < epsilon);
# GP-DEFINE  }

# GP-DEFINE  dcross(n) = n>=0 || error(); if(n==0,1, 2^(n-1));
# GP-DEFINE  \\ dcross(n) = if(n==0,'o, eval(Str("'t",n-1)));
# for(n=0,10,print(d(n)))
# GP-DEFINE  d(n) = n>=0 || error(); if(n==0,0, 2*dg(n-1) + dcross(n-1));
# GP-DEFINE  dg(n) = n>=0 || error(); if(n==0,0, dg(n-1) + dh(n-1) + dcross(n-1));
# GP-DEFINE  dh(n) = n>=0 || error(); if(n==0,0,n==1,1, d(n-2) + dg(n-1) + dcross(n-1));
# GP-DEFINE  d=memoize(d);
# GP-DEFINE  dg=memoize(dg);
# GP-DEFINE  dh=memoize(dh);
# GP-DEFINE  A341583(n) = d(n);
# GP-Test  d(0) == 0 && f(0) == 0
# GP-Test  d(1) == 1 && f(1) == 1
# GP-Test  d(2) == 3 && f(2) == 3
# GP-Test  dg(2) == 3 && g(2) == 3
# GP-Test  d(3) == 8 && f(3)  == 7
# GP-Test  dg(3) == 7 && g(3)  == 6
# GP-Test  vector(5,n,n--; dcross(n)) == [1,1,2,4,8]
# GP-Test  vector(5,n,n--; lex(d(n), f(n))) == \
# GP-Test  vector(5,n,n--; if(n<=2,0, 1))
# GP-Test  vector(5,n,n--; lex(dg(n), g(n))) == \
# GP-Test  vector(5,n,n--; if(n<=2,0, 1))
# GP-Test  vector(5,n,n--; lex(dh(n), h(n))) == \
# GP-Test  vector(5,n,n--; if(n<=2,0, 1))
# vector(10,n,n--; dh(n))
# vector(10,n,n--; h(n))
# vector(10,n,n--; dcross(n))
# not in OEIS: 5, 11, 29, 69, 161, 361, 801, 1745, 3761, 8017
# OEIS_recurrence_guess(vector(100,n,n--;d(n)))
# for(n=0,36,print1(fmoves(n),",");if(n==19||n==29,print()))
#
# GP-Test  my(want=OEIS_samples("A341583")); /* OFFSET=0 */ \
# GP-Test    vector(#want,n,n--; A341583(n)) == want
# GP-Test  my(want=OEIS_bfile_samples("A341583")); /* OFFSET=0 */ \
# GP-Test    print("b341583  ",#want); \
# GP-Test    vector(#want,n,n--; A341583(n)) == want
#
# GP-Test  /* d in terms of f */ \
# GP-Test  vector(100,n,n--; d(n)) == \
# GP-Test  vector(100,n,n--; (7*2^n - f(n+3) + f(n))/2)
# GP-Test  my(a=A341583); \
# GP-Test  vector(100,n,n--; a(n)) == \
# GP-Test  vector(100,n,n--; (7*2^n - A341579(n+3) + A341579(n))/2)
#
# GP-Test  /* d full recurrence */ \
# GP-Test  my(a=d); \
# GP-Test  vector(100,n,n+=4; a(n)) == \
# GP-Test  vector(100,n,n+=4; 3*a(n-1) - a(n-2) - 2*a(n-3) + 2*a(n-4) - 4*a(n-5))
#
# GP-DEFINE  gd(x) = {
# GP-DEFINE    7/2/(1 - 2*x)
# GP-DEFINE    - 1/2*(7 + 5*x + 3*x^2 + 6*x^3)/(1 - x - x^2 - 2*x^4);
# GP-DEFINE  }
# GP-Test  gd(x) + O(x^100) == sum(n=0,100, d(n)*x^n)
# GP-Test  gd(x) == x * (1 - x) * (1 + x + x^2) / ( (1 - 2*x) * (1 - x - x^2 - 2*x^4) )
# GP-Test  gd(x) == (7/2)/(1 - 2*x) - (1/2)*(7 + 5*x + 3*x^2 + 6*x^3)/(1 - x - x^2 - 2*x^4)
#
# GP-Test  polisirreducible('x^4-'x^3-'x^2-2)  /* in d_compact polmod */
# GP-DEFINE  my(p=Mod('x,'x^4-'x^3-'x^2-2), f=6*'x^3+5*'x^2+3*'x+7); \
# GP-DEFINE    d_compact(n) = (7<<n - polcoeff(lift(f*p^n),0))/2;
# GP-Test  vector(200,n,n--; d(n)) == \
# GP-Test  vector(200,n,n--; d_compact(n))
#
# GP-DEFINE  \\ prefer f looking like gd(x) numerator
# GP-DEFINE  my(p=Mod('x,'x^4-'x^3-'x^2-2), f=7*'x^3+5*'x^2+3*'x+6); \
# GP-DEFINE    d_compact(n) = (7<<n - polcoeff(lift(f*p^n),3))/2;
# GP-Test  vector(200,n,n--; d(n)) == \
# GP-Test  vector(200,n,n--; d_compact(n))

# GP-DEFINE  \\ Stockmeyer et al
# GP-DEFINE  d_inexact(n) = {
# GP-DEFINE    7/2*2^n - 3.19914 *(1.85356)^n - 0.10227*(-1.15673)^n
# GP-DEFINE            - 0.19858 *(0.96582)^n *cos(1.41320*n)
# GP-DEFINE            - 0.16606 *(0.96582)^n *sin(1.41320*n);
# GP-DEFINE  }
# GP-Test  my(n=0); nearly_equal(d(n), d_inexact(n), 1e-4)
# GP-Test  my(n=1); nearly_equal(d(n), d_inexact(n), 1e-4)
# GP-Test  my(n=2); nearly_equal(d(n), d_inexact(n), 1e-4)
# GP-Test  my(n=3); nearly_equal(d(n), d_inexact(n), 1e-4)
# GP-Test  vector(10,n, nearly_equal(d(n), d_inexact(n), 1e-1)) == \
# GP-Test  vector(10,n, 1)
# vector(5,n,n--; d_inexact(n))
# vector(5,n,n--; d(n))
# vector(5,n,n--; 7*2^n - 2*d(n))
# polroots(f_poly(x))
#  1
# -1.1567
#  1.8535
#  0.15158 - 0.9538*I
#  0.15158 + 0.9538*I
# my(v=polroots(f_poly(x))); abs(v[1])
# my(v=polroots(f_poly(x))); abs(v[3])
# not in OEIS: 1.85356027758424
# not in OEIS: 1.1567277753569
# my(v=polroots(f_poly(x))); arg(v[#v])
# my(v=polroots(f_poly(x))); arg(v[#v])*180/Pi
# not in OEIS: 1.4131964441  \\ radians
# not in OEIS: 80.9701918    \\ degrees
# GP-Test  f_poly(x)/(x-1) == x^4 - x^3 - x^2 - 2

# GP-DEFINE  recurrence_coeffs_to_matrix(coeffs) = {
# GP-DEFINE    matrix(#coeffs,#coeffs,r,c,
# GP-DEFINE           if(c==r+1,1, r==#coeffs,coeffs[c]));
# GP-DEFINE  }
# GP-DEFINE  recurrence_eval(coeffs,initial,k) = {
# GP-DEFINE    my(skip=#initial-#coeffs);
# GP-DEFINE    if(skip && k<skip, return(initial[k+1]));
# GP-DEFINE    initial=initial[skip+1 .. #initial];
# GP-DEFINE    k-=skip;
# GP-DEFINE    (recurrence_coeffs_to_matrix(coeffs)^k * Col(initial))[1];
# GP-DEFINE  }
#
# GP-DEFINE  \\ difference d(n) - 7/2*2^n so its recurrence part only
# GP-DEFINE  ddiff(n) = recurrence_eval([-2,2,-1,0,2],[7, 12, 22, 40, 76],n);
# GP-Test  vector(100,n,n--; ddiff(n)) == \
# GP-Test  vector(100,n,n--; 7*2^n - 2*d(n))
# GP-Test  /* ddiff two terms of f */ \
# GP-Test  vector(100,n,n--; ddiff(n)) == \
# GP-Test  vector(100,n,n--; f(n+3) - f(n))
#
# vector(25,n,n-=15; ddiff(n))
# for(o=-5,8, my(f=f);\
# print(o" "lindep([vector(12,n,n+=15; ddiff(n)),\
#               vector(12,n,n+=15; f(o+n)),\
#               vector(12,n,n+=15; f(o+n-1)),\
#               vector(12,n,n+=15; f(o+n-2)),\
#               vector(12,n,n+=15; f(o+n-3)),\
#               vector(12,n,n+=15; f(o+n-4))])))

=pod

=head1 HOUSE OF GRAPHS

House of Graphs entries for graphs here include

=over

L<https://hog.grinvin.org/ViewGraphInfo.action?id=21136> (etc)

=back

    spindles=3 (default)
      discs=0        1310  singleton
      discs=1        1374  triangle
      discs=2       21136  same as plain Hanoi
      discs=3       44105
      discs=4       44107
      discs=5       44109

=head1 SEE ALSO

L<Graph::Maker>,
L<Graph::Maker::Hanoi>,
L<Graph::Maker::Complete>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/graph-maker-other/index.html>

=head1 LICENSE

Copyright 2021 Kevin Ryde

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
