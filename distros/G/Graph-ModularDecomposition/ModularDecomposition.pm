package Graph::ModularDecomposition;

use 5.006;
use strict;
use warnings;

=head1 NAME

Graph::ModularDecomposition - Modular decomposition of directed graphs

=cut

require Exporter;
our $VERSION = '0.15';

use Graph 0.20105;
require Graph::Directed;

# NB! Exporter must come before Graph::Directed in @ISA
our @ISA = qw(Exporter Graph::Directed);

# This allows declaration	use Graph::ModularDecomposition ':all';
# may want tree_to_string, should move into own Tree::... module some day
# other exports are most likely for internal use only
# all other functions should be accessed as methods
our %EXPORT_TAGS = ( 'all' => [ qw(
	setminus
	setunion
	pairstring_to_graph
	partition_to_string
	tree_to_string
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

=head1 SYNOPSIS

    use Graph::ModularDecomposition qw(pairstring_to_graph tree_to_string);
    my $g = new Graph::ModularDecomposition;

    my $h = $g->pairstring_to_graph( 'ab,ac,bc' );
    print "yes\n" if check_transitive( $h );
    print "yes\n" if $h->check_transitive; # same thing
    my $m = $h->modular_decomposition_EGMS;
    print tree_to_string( $m );


=head1 DESCRIPTION

This module extends L<Graph::Directed|Graph::Directed> by providing
new methods related to modular decomposition.

The most important new method is modular_decomposition_EGMS(), which
for a directed graph with n vertices finds the modular decomposition
tree of the graph in O(n^2) time.  Method tree_to_string() may be
useful to represent the decomposition tree in a friendlier format;
this needs to be explicitly imported.

If you need to decompose an undirected graph, represent it as a
directed graph by adding two directed edges for each undirected edge.

The method classify() uses the modular decomposition tree to classify
a directed graph as non-transitive, or for transitive digraphs,
as series-parallel (linear or parallel modules only), decomposable
(not series-parallel, but with at least one non-primitive module),
indecomposable (primitive), decomposable but consisting of primitive
or series modules only (only applies to graphs of at least 7 vertices),
or unclassified (should never apply).

=head2 RELATED WORK

Several graph algorithms use the modular decomposition tree as a
building block.  A simple example application of these routines is
to construct and search the modular decomposition tree of a directed
graph to determine if it is node-series-parallel.
Checking if a digraph is series-parallel can also be determined using
the O(m+n) Valdes-Tarjan-Lawler algorithm published in 1982, but this
only constructs a decomposition tree if the input is series-parallel:
other inputs are simply classified as non-series-parallel.

The code here is based on algorithm 6.1 for modular decomposition of
two-structures, from

A. Ehrenfeucht, H. N. Gabow, R. M. McConnell, and S. J. Sullivan, "An
O(n^2) Divide-and-Conquer Algorithm for the Prime Tree Decomposition
of Two-Structures and Modular Decomposition of Graphs", Journal of
Algorithms 16 (1994), pp. 283-294.  doi:10.1006/jagm.1994.1013

I am not aware of any other publicly available implementations.
Any errors and omissions are of course my fault.  Better algorithms
are known: O(m+n) run-time can be achieved using sophisticated data
structures (where m is the number of edges in the graph), see

R. M. McConnell and F. de Montgolfier, "Linear-time modular
decomposition of directed graphs", Discrete Applied Mathematics
145 (2005), pp. 198-209.  doi:10.1016/j.dam.2004.02.017


=head2 EXPORT

None by default.  Methods tree_to_string() and partition_to_string()
can be imported.  Methods setminus() and setunion() are for internal
use but can also be imported.


=head2 METHODS

=over 4

=item debug()

    my $g = new Graph::ModularDecomposition;
    Graph::ModularDecomposition->debug(1); # turn on debugging
    Graph::ModularDecomposition->debug(2); # extra debugging
    $g->debug(2); # same thing
    $g->debug(0); # off (default)

Manipulates the debug level of this module.  Debug output is sent
to STDERR.  Object-level debugging is not yet supported.

=cut

use Carp;

my $VSEP = '|'; # string used to separate vertices
my $WSEP = '\|'; # regexp used to separate vertices
my $PSEP = '\+'; # regexp used to separate elements of partition
my $QSEP = '+'; # string used to separate elements of partition

my $MD_Debug = 0;

sub debug {
    my $class = shift;
    if ( ref($class) ) { $class = ref($class) }
    $MD_Debug = shift;
    carp 'Turning ', ($MD_Debug ? 'on' : 'off'), ' ',
	$class, ' debugging', ($MD_Debug ? ", level $MD_Debug" : '');
}


=item canonical_form()

    my $g = new Graph::ModularDecomposition;
    Graph::ModularDecomposition->canonical_form(1); # on (default)
    Graph::ModularDecomposition->canonical_form(0); # off
    $g->canonical_form(1); # same thing
    $g->canonical_form(0); # off
    print "yes" if $g->canonical_form();

Manipulates whether this module keeps modular decomposition trees in
"canonical" form, where lists of vertices are kept sorted.  This allows
tree_to_string() on two isomorphic decomposition trees to produce the
same output (well, sometimes -- a more general solution requires an
isomorphism test).  Canonical form forces sorting of vertices in several
places, which will slow down some of the algorithms.  When called with
no arguments, returns the current state.

=cut

my $Canonical_form = 1;

sub canonical_form {
    my $class = shift;
    if ( ref($class) ) { $class = ref($class) }
    my $cf = shift;
    return $Canonical_form unless defined $cf;
    $Canonical_form = $cf;
}


=item new()

    my $g = new Graph::ModularDecomposition;
    $g = Graph::ModularDecomposition->new; # same thing
    my $h = $g->new;

Constructor.  The instance method style C<< $object->new >> is an extension
and was not present in L<Graph::Directed|Graph::Directed>.

=cut

sub new {
    my $self = shift;
    my $class = ref($self) ? ref($self) : $self;
    return bless $class->SUPER::new(@_,directed=>1), $class;
}


=item pairstring_to_graph

    my $g = Graph::ModularDecomposition
	->pairstring_to_graph( 'ac, ad, bd' );
    my $h = $g->pairstring_to_graph( 'a-c,  a-d,b-d' ); # same thing
    my $h = $g->pairstring_to_graph( 'a,b,c,d,a-c,a-d,b-d' ); # same thing

    use Graph::ModularDecomposition qw( pairstring_to_graph );
    my $k = pairstring_to_graph( 'Graph::ModularDecomposition',
	'ac,ad,bd' ); # same thing

Convert string of pairs input to Graph::ModularDecomposition output.
Allows either 'a-b,b-c,d' or 'ab,bc,d' style notation but these should
not be mixed in one string.  Vertex labels should not include the
'-' character.  Use the '-' style if multi-character vertex labels
are in use.  Single label "pairs" are interpreted as vertices to add.

=cut

sub pairstring_to_graph {
    my $class = shift;
    if ( ref($class) ) { $class = ref($class) }
    my $pairs = shift;
    my $g = new $class;
    my ($p, $q);
    my $s = ( ( index( $pairs, '-' ) >= 0 ) ? '\-' : '' );
    foreach my $r ( split /,\s*/, $pairs ) {
	( $p, $q ) = split $s, $r;
	print "p=$p, q=$q\n" if $MD_Debug > 2;
	if ( $q ) {
	    $g = $g->add_edge( $p, $q ) unless $g->has_edge( $p, $q );
	} else {
	    $g = $g->add_vertex( $p ) unless $g->has_vertex( $p );
	}
    }
    return bless $g, $class;
}


=item check_transitive()

    my $g = new Graph::ModularDecomposition;
    # add some edges...
    print "transitive" if $g->check_transitive;

Returns 1 if input digraph is transitive, '' otherwise.  May break if
Graph::stringify lists vertices in unsorted order.

=cut

sub check_transitive {
    my $g = shift;
    my $g2 = $g->copy;
    my $h = $g->TransitiveClosure_Floyd_Warshall;
    # get rid of loops
    foreach ( $h->vertices ) { $h->delete_edge( $_, $_ ) }
    foreach ( $g2->vertices ) { $g2->delete_edge( $_, $_ ) }
    print STDERR "gdct: ", $g, ' vs. ', $h, "\n" if $MD_Debug;
    return $h eq $g2;
}


=item setminus()

    my @d = setminus( ['a','b','c'], ['b','d'] ); # ('a','c')

Given two references to lists, returns the set difference of the two
lists as a list.  Can be imported.

=cut

sub setminus {
    my $X = shift;
    my $Y = shift;
    my @X = @{$X};
    print STDERR 'setminus# ', @X, ' - ', @{$Y}, ' = ' if $MD_Debug > 1;
    foreach my $x ( @{$Y} ) {
	@X = grep $x ne $_, @X;
    }
    print STDERR @X, "\n" if $MD_Debug > 1;
    return @X;
}


=item setunion()

    my @u = setunion(['a','bc',42], [42,4,'a','c']);
    # ('a','bc',42,4,'c')

Given two references to lists, returns the set union of the two lists
as a list.  Can be imported.

=cut

sub setunion {
    my $X = shift;
    my $Y = shift;
    my @X = @{$X};
    print STDERR 'setunion# ', @X, ' U ', @{$Y}, ' = ' if $MD_Debug > 1;
    foreach my $x ( @{$Y} ) {
	push @X, $x unless grep $x eq $_, @X;
    }
    print STDERR @X, "\n" if $MD_Debug > 1;
    return sort @X;
}


=item restriction()

    use Graph::ModularDecomposition;
    my $G = new Graph::ModularDecomposition;
    foreach ( 'ac', 'ad', 'bd' ) { $G->add_edge( split // ) }
    restriction( $G, split(//, 'abdefgh') ); # a-d,b-d
    $G->restriction( split(//, 'abdefgh') ); # same thing

Compute G|X, the subgraph of G induced by X.  X is represented as a
list of vertices.

=cut

sub restriction {
    my $G = shift;
    if ( $MD_Debug > 2 ) { print STDERR 'restriction(', ref($G), ")\n" }
    my $h = ($G->copy)->delete_vertices( setminus( [$G->vertices], [@_] ) );
    if ( $MD_Debug > 1 ) {
	print STDERR 'restriction(', $G, '|', join($QSEP, @_), ') = ', $h, "\n"
    }
    return $h;
}


=item factor()

    $h = factor( $g, [['a','b'], ['c'], ['d','e','f']] );
    $h = $g->factor( [[qw(a b)], ['c'], [qw(d e f)]] ); # same thing

Compute G/P for partition P containing modules.  Will fail in odd
ways if members of P are not modules.

=cut

sub factor {
    my $G = shift;
    my $P = shift;
    my $GP = $G->copy;
    my $p;
    foreach my $X ( @{$P} ) {
	print STDERR "factor# X = $X\n" if $MD_Debug > 1;
	print STDERR "factor# \@X = @$X\n" if $MD_Debug > 1;
	my $newnode = join $VSEP, @{$X}; # turn nodes a, b, c into new node abc
	print STDERR "factor# newnode = $newnode\n" if $MD_Debug > 1;
	my $a = ${$X}[0];
	print STDERR "factor# representative node $a\n" if $MD_Debug > 1;
	if ( $newnode ne $a ) { # do nothing if singleton
	    $GP->add_vertex( $newnode );
	    foreach $p ( $GP->predecessors( $a ) ) {
		print STDERR "factor# predecessor $p\n" if $MD_Debug > 2;
		$GP = $GP->add_edge( $p, $newnode )
		    unless $GP->has_edge( $p, $newnode );
	    }
	    foreach $p ( $GP->successors( $a ) ) {
		print STDERR "factor# successor $p\n" if $MD_Debug > 2;
		$GP = $GP->add_edge( $newnode, $p )
		    unless $GP->has_edge( $newnode, $p );
	    }
	    $GP = $GP->delete_vertices( @{$X} );
	}
    }
    return $GP;
}


=item partition_subsets()

    @part = partition_subsets( $G, ['a','b','c'], $w );
    @part = $G->partition_subsets( ['a','b','c'], $w ); # same thing

Partition set of vertices into maximal subsets not distinguished by w in G.

=cut

sub partition_subsets {
    my $G = shift;
    my $S = shift;
    my $w = shift;

    print STDERR 'p..n_subsets# @S = ', @{$S}, ", w = $w \n" if $MD_Debug > 1;
    my (@A, @B, @C, @D);
    foreach my $x ( @{$S} ) {
	print STDERR 'p..n_subsets# xw = ', $x, $w if $MD_Debug > 2;
	if ( $G->has_edge( $w, $x ) ) {
	    if ( $G->has_edge( $x, $w ) ) { # xw wx (not poset)
		push @A, $x;
		print STDERR ' A = ', @A, "\n" if $MD_Debug > 2;
	    } else { # ~xw wx
		push @B, $x;
		print STDERR ' B = ', @B, "\n" if $MD_Debug > 2;
	    }
	} else {
	    if ( $G->has_edge( $x, $w ) ) { # xw ~wx
		push @C, $x;
		print STDERR ' C = ', @C, "\n" if $MD_Debug > 2;
	    } else { # ~xw ~wx
		push @D, $x;
		print STDERR ' D = ', @D, "\n" if $MD_Debug > 2;
	    }
	}
    }
    return grep @{$_}, (\@A, \@B, \@C, \@D);
}


=item partition()

    my $p = partition( $g, $v );
    $p = $g->partition( $v ); # same thing

For a graph, calculate maximal modules not including a given vertex.

=cut

sub partition {
    my $G = shift;
    my $v = shift;

    print STDERR 'partition# G = ', $G, ", v = $v\n" if $MD_Debug > 1;
    my (%L, @done, $tempset, $S, @ZS, $w);
    $S = [ setminus( [ $G->vertices ], [ $v ] ) ];
    print STDERR 'partition# @S = ', @{$S}, "\n" if $MD_Debug > 1;
    $L{$S} = [ $v ];
    my @todo = ( $S );
    print STDERR 'partition# L{S}[0] = ', $L{$S}[0], "\n" if $MD_Debug > 1;
    while ( @todo ) {
	$S = shift @todo;
	@ZS = @{$L{$S}};
	$w = $ZS[0];
	print STDERR 'partition# ZS = ', @ZS, "\n" if $MD_Debug > 1;
	delete $L{$S};
	foreach my $W ( $G->partition_subsets( $S, $w ) ) {
	    print STDERR 'partition# W = ', @{$W}, "\n" if $MD_Debug > 1;
	    $tempset = [ setunion( [ setminus( $S, $W ) ],
				[ setminus( \@ZS, [ $w ] ) ] ) ];
	    if ( @{$tempset} ) {
		print STDERR 'partition# tempset = ', @{$tempset}, "\n"
		    if $MD_Debug > 1;
		$L{$W} = $tempset;
		push @todo, $W;
	    } else {
		push @done, $W;
	    }
	}
    }
    return \@done;
}


=item distinguishes()

    print "yes" if distinguishes( $g, $x, $y, $z );
    print "yes" if $g->distinguishes( $x, $y, $z ); # same thing

True if vertex $x distinguishes vertices $y and $z in graph $g.

=cut

sub distinguishes {
    my ($g,$x,$y,$z) = @_;
    print STDERR " $x$y?", $g->has_edge($x,$y) if $MD_Debug > 1;
    print STDERR " $x$z?", $g->has_edge($x,$z) if $MD_Debug > 1;
    print STDERR " $y$x?", $g->has_edge($y,$x) if $MD_Debug > 1;
    print STDERR " $z$x?", $g->has_edge($z,$x) if $MD_Debug > 1;
    my $ret =  ( $g->has_edge($x,$y) != $g->has_edge($x,$z) )
	    || ( $g->has_edge($y,$x) != $g->has_edge($z,$x) );
    print STDERR "=$ret\n" if $MD_Debug > 1;
    return $ret;
}


=item G()

    $G = G( $g, $v );
    $G = $g->G( $v ); # same thing

"Trivially" calculate G(g,v).  dom(G(g,v)) = dom(g)\{v}, and (x,y) is
an edge of G(g,v) whenever x distinguishes y and v in g.

=cut

sub G {
    my $g = shift;
    my $v = shift;
    my $G = new ref($g);
    print STDERR 'G([', $g, "], $v) =...\n" if $MD_Debug;
X:  foreach my $x ( $g->vertices ) {
	next X if ( $v eq $x );
	print STDERR 'X=', $x, "\n" if $MD_Debug > 1;
	$G = $G->add_vertex( $x );
Y:	foreach my $y ( $g->vertices ) {
	    next Y if ( $v eq $y or $x eq $y );
	    print STDERR 'Y=', $y, "\n" if $MD_Debug > 1;
	    if ( $g->distinguishes( $x, $y, $v ) ) {
		$G = $G->add_edge( $x, $y ) unless $G->has_edge( $x, $y );
	    }
	}
    }
    print STDERR '...G()=', $G, "\n" if $MD_Debug;
    return $G;
}


=item tree_to_string()

    print tree_to_string( $t );

String representation of decomposition tree.  Returns empty string for
an empty decomposition tree.  Needs to be explicitly imported.  If
Graph::vertices returns the vertices in unsorted order, then isomorphic
trees can have different string representations.

=cut

sub tree_to_string {
    my $t = shift;
    my $s = '';
    return $s unless defined $t->{type};
    $s .= $t->{type} if $t->{type} ne 'leaf';
    $s .= '_' . $t->{col} if ( $t->{type} eq 'complete' );
    $s .= '[' . $t->{value} . ']';
    if ( $t->{type} ne 'leaf' ) {
	my $sep = '';
	$s .= '(';
	foreach ( @{$t->{children}} ) {
	    $s .= $sep . tree_to_string( $_ );
	    $sep = ';';
	}
	$s .= ')';
    }
    return $s;
}


=item partition_to_string

    print partition_to_string([['h'], [qw(c a b)], [qw(d e f g)]]);
    # a+b+c,d+e+f+g,h

String representation of partition.  Returns empty string for an
empty partition.  Needs to be explicitly imported.

=cut

sub partition_to_string {
    return join ',', sort (map { join $QSEP, sort @{$_} } @{+shift});
}


=item modular_decomposition_EGMS()

    use Graph::ModularDecomposition;
    $g = new Graph::ModularDecomposition;
    $m = $g->modular_decomposition_EGMS;

Compute modular decomposition tree of the input, which must be
a Graph::ModularDecomposition object, using algorithm 6.1 of
A. Ehrenfeucht, H. N. Gabow, R. M. McConnell, S. J. Sullivan, "An
O(n^2) Divide-and-Conquer Algorithm for the Prime Tree Decomposition
of Two-Structures and Modular Decomposition of Graphs", Journal of
Algorithms 16 (1994), pp. 283-294.

The decomposition tree consists of nodes with attributes: 'type' is
a string matching /^leaf|primitive|complete|linear$/, 'children' is
a reference to a potentially empty list of pointers to other nodes,
'value' is a string with the vertices in the decomposition defined
by the tree, separated by '|' (VSEP), and 'col' is a string containing the
colour of the module, matching /^0|1|01$/.  A node with 'type' of
'complete' is parallel if 'col' is '0' and series if 'col' is '1'.
A node with 'type' of 'linear' has 'col' of '01'.  Use the function
tree_to_string() to convert the tree into a more generally usable form.

=cut

sub modular_decomposition_EGMS {
    my $g = shift;
    my $md = 0;
    $md ++;
    my $B = ' 'x$md;
    print STDERR $B, 'MD(', $g, ")=...\n" if $MD_Debug;
    my $v = ($g->vertices)[0];
    print STDERR $B, 'v=', (defined($v) ? $v : 'undef'), "\n" if $MD_Debug;

    my $t = {};
    unless ( $v ) {
	print STDERR $B, '...MD=', tree_to_string( $t ), "\n" if $MD_Debug;
	$md --;
	return $t;
    }
    $t->{type} = 'leaf';
    $t->{children} = [];
    if ($g->canonical_form()) {
	$t->{value} = join($VSEP, sort($g->vertices));
    } else {
	$t->{value} = join($VSEP, $g->vertices);
    }
    $t->{col} = '0';

    if ( scalar $g->vertices == 1 ) {
	print STDERR $B, '...MD=', tree_to_string( $t ), "\n" if $MD_Debug;
	$md --;
	return $t;
    }

    my $p = partition( $g, $v );
    push @{$p}, [ $v ];
    my $gd = $g->factor( $p );
    print STDERR $B, 'gd = ', $gd, "\n" if $MD_Debug;
    my $Gdd = $gd->G($v)->strongly_connected_graph;
    print STDERR $B, 'Gdd = [', $Gdd, '], ', scalar $Gdd->vertices, "\n" if $MD_Debug;

    my $u = $t;
    my @f;
    while ( @f = grep( $Gdd->out_degree($_) == 0 , $Gdd->vertices ) ) {
	print STDERR $B, "\@f=[@f]\n" if $MD_Debug;
	my @s;
	foreach my $s ( $Gdd->vertices ) {
	    push @s, split(/$PSEP/, $s);
	}
	if ($g->canonical_form()) {
	    $u->{value} = join('', sort($v, @s));
	} else {
	    $u->{value} = join('', ($v, @s));
	}
	my $w = {};
	$w->{type} = 'leaf';
	$w->{children} = [];
	$w->{value} = $v;
	$w->{col} = '0';
	push @{$u->{children}}, $w;

	$Gdd->delete_vertices( @f );
	my @F;
	foreach my $f ( @f ) {
	    foreach my $F ( split /$PSEP/, $f ) {
		push @F, $F unless grep $F eq $_, @F;
	    }
	}
	print STDERR $B, "\@F=@F\n" if $MD_Debug;
	if ( @f == 1 and @F > 1 ) {
	    $u->{type} = 'primitive';
	    $u->{col} = '0';
	} else {
	    my $x = substr $F[0], 0, 1; # single-char vertex names!
	    if ( $g->has_edge($v, $x) == $g->has_edge($x, $v) ) {
		$u->{type} = 'complete'; # 0 parallel, 1 series
		$u->{col} = $g->has_edge($v, $x) ? '1' : '0';
	    } else {
		$u->{type} = 'linear';
		$u->{col} = '01';
	    }
	}
	print STDERR $B, 'u = ', tree_to_string( $u ), "\n" if $MD_Debug;
	foreach my $X ( @F ) {
	    my $m = $g->restriction( split /$WSEP/, $X )
		    ->modular_decomposition_EGMS;
	    if ( defined $m->{col}
		and ( $u->{col} eq $m->{col} )
		and (
		    ( $u->{type} eq 'complete' and $m->{type} eq 'complete' )
		   or ( $u->{type} eq 'linear' and $m->{type} eq 'linear' )
		)
	    ) {
		if ( $MD_Debug ) {
		    print STDERR $B, "u->children= @{$u->{children}}\n";
		    print STDERR $B, 'm->children= ';
		    my $sep = '';
		    foreach ( @{$m->{children}} ) {
			print STDERR $sep, '[', tree_to_string( $_ ), ']';
			$sep = ', ';
		    }
		    print STDERR "\n";
		}
		push @{$u->{children}}, @{$m->{children}};
	    } else {
		push @{$u->{children}}, $m;
	    }
	}
	$u = $w;
    }
    print STDERR $B, '...MD=', tree_to_string( $t ), "\n" if $MD_Debug;
    $md --;
    return $t;
}


=item classify()

    use Graph::ModularDecomposition;
    my $g = new Graph::ModularDecomposition;
    my $c = classify( $g );
    $c = $g->classify; # same thing

Based on the modular decomposition tree, returns:
    n	non-transitive
    i	indecomposable
    d	decomposable but not SP, at least one non-primitive node
    s	series-parallel
    p	decomposable but each module is primitive or series
    u	unclassified: should not happen

=cut

sub classify {
    my $g = shift;
    return 'n' unless $g->check_transitive;
    my $s = tree_to_string( $g->modular_decomposition_EGMS );
    return 'i' if $s =~ m/^primitive\[[^\]]+\]\([^\(]*$/;
    return 'd' if $s =~ m/primitive/ and $s =~ m/complete_|linear/;
    return 's' if $s !~ m/primitive|complete_1/; # matches empty string
    return 'p' if $s =~ m/primitive|complete_1/;
    return 'u';
}


=item to_bitvector2()

    $b = $g->to_bitvector2;

Convert input graph to Bitvector2 output.
L<Graph::Directed|Graph::Directed> version 20104 permits
multi-edges; these will be collapsed into a single edge in the
output Bitvector2.  The Bitvector2 is relative to the unique
lexicographic ordering of the vertices.  This method is only present
if L<Graph::Bitvector2|Graph::Bitvector2> is found.

=cut

eval {require Graph::Bitvector2; 1} and # alas, circular dependency here
eval q{
    sub to_bitvector2 {
	my $g = shift;
	my @v = sort $g->vertices;
	my @bits;
	while ( @v ) {
	    my $x = shift @v;
	    foreach my $y ( @v ) {
		push @bits, (
		    $g->has_edge( $x, $y )
		    ? 1
		    : ( $g->has_edge( $y, $x ) ?  2 : 0 )
		);
	    }
	}
	return new Graph::Bitvector2 (join '', @bits);
    }
};


=back

=cut

1;
__END__

=head1 AUTHOR

Andras Salamon, E<lt>azs@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2004-17, Andras Salamon.

This code is distributed under the same copyright terms as Perl itself.
                                                                                
=head1 SEE ALSO

L<perl>, L<Graph>, L<Graph::Bitvector2>.

=cut
