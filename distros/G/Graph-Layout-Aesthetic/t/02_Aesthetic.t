#!/usr/bin/perl -w
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 02_Aesthetic.t'

use strict;
use warnings;
BEGIN { $^W = 1 };
use Test::More "no_plan";

my @warnings;
$SIG{__WARN__} = sub { push @warnings, shift };
sub check_warnings {
    is(@warnings, 0, "No warnings");
    if (@warnings) {
        diag("Unexpected warnings:");
        diag($_) for @warnings;
    }
    @warnings = ();
}

END {
    # Final warnings check
    check_warnings();
}

BEGIN { use_ok('Graph::Layout::Aesthetic') };
BEGIN { use_ok('Graph::Layout::Aesthetic::Topology') };
BEGIN { use_ok('Graph::Layout::Aesthetic::Force::NodeRepulsion') };
BEGIN { use_ok('Graph::Layout::Aesthetic::Force::MinEdgeLength') };

# Used to check if some reference has reference count zero (is destructive)
{
    package KillRef;
    my $killrefs;
    sub test {
        my $class = shift;
        $killrefs = 0;
        bless $_[0], $class;
        $_[0] = undef;
        main::is($killrefs, 1, "Properly cleaned");
    }

    sub DESTROY {
        $killrefs++;
    }
}

{
    package MagicArray;
    use base qw(Tie::Array);

    sub TIEARRAY {
        my $array = bless [], shift;
        @$array = @_;
        return $array;
    }

    sub FETCH {
        my ($array, $index) = @_;
        return $array->[$index];
    }

    sub FETCHSIZE {
        my $array = shift;
        return scalar @$array;
    }

    sub STORE {
        my ($array, $index, $value) = @_;
        $array->[$index] = $value;
    }
}

my $destroys;
{
    my $f = \&Graph::Layout::Aesthetic::DESTROY;
    no warnings 'redefine';
    *Graph::Layout::Aesthetic::DESTROY = sub($ ) {
        $destroys++;
        $f->(@_);
    }
}

my $topo_destroys;
{
    my $f = \&Graph::Layout::Aesthetic::Topology::DESTROY;
    no warnings 'redefine';
    *Graph::Layout::Aesthetic::Topology::DESTROY = sub($ ) {
        $topo_destroys++;
        $f->(@_);
    }
}

my $force_destroys;
{
    my $f = \&Graph::Layout::Aesthetic::Force::DESTROY;
    no warnings 'redefine';
    *Graph::Layout::Aesthetic::Force::DESTROY = sub($ ) {
        $force_destroys++;
        $f->(@_);
    }
}

my $count;
my $monitors = 0;
{
    package TestMonitor;
    sub new {
        $monitors++;
        return bless [], shift;
    }

    sub plot {
        $count++;
    }

    sub DESTROY {
        $monitors--;
    }
}

# Check if a value is close to anouther
our $EPS = 1e-8;
sub nearly {
    my $val    = shift;
    my $target = shift;
    my ($low, $high) =
        $target > 0 ? ($target * (1-$EPS), $target * (1+$EPS)) :
        $target < 0 ? ($target * (1+$EPS), $target * (1-$EPS)) :
        (-$EPS, +$EPS);
    if ($low < $val && $val < $high) {
        pass(@_ ? shift: ());
    } else {
        diag("$val is not close to $target");
        fail(@_ ? shift : ());
    }
}

# Check if some function is random enough by putting the results in bins
# and seeing if all bins get filled
sub is_random {
    my ($aglo, $f) = @_;

    my @bins = ();
    my $size = 10;
    my $seen = 0;
    my $loops = 0;
    my $max_loops = 100000;
    my $expected = 2*$size*$aglo->nr_dimensions*$aglo->topology->nr_vertices;
  TRY:
    while ($loops < $max_loops) {
        $f->($aglo, $size);
        my $i=0;
        for ($aglo->all_coordinates) {
            for (@$_) {
                if ($_ <= -$size || $_ >= $size) {
                    diag("Value $_ is outside [-$size, $size]");
                    fail("Value outside [-$size, $size]");
                    last TRY;
                }
                my $pos = int($size+$_);
                $bins[$i][$pos] ||= ++$seen;
                $i++;
            }
        }
        $loops++;
        last if $seen == $expected;
    }
    ok($loops < $max_loops, "All values reached");
    is($seen, $expected, "All values reached");
}

# Check if some function is random enough by putting the results in bins
# and seeing if all bins get filled
sub g_is_random {
    my ($g, $f, $mul, $d) = @_;

    $d   ||= 2;
    $mul ||= 1;
    my @bins = ();
    my $size = 10;
    my $seen = 0;
    my $loops = 0;
    my $max_loops = 10000;
    my $expected = 2*$size*$d*$g->vertices;
  TRY:
    while ($loops < $max_loops) {
        $f->($g);
        my $i=0;
        for ($g->vertices) {
            my $pos = $g->get_vertex_attribute($_, "layout_pos");
            for (@$pos) {
                $_ *= $mul * $size;
                if ($_ <= -$size || $_ >= $size) {
                    diag("Value $_ is outside [-$size, $size]");
                    fail("Value outside [-$size, $size]");
                    last TRY;
                }
                my $pos = int($size+$_);
                $bins[$i][$pos] ||= ++$seen;
                $i++;
            }
        }
        $loops++;
        last if $seen == $expected;
    }
    ok($loops < $max_loops, "All values reached");
    is($seen, $expected, "All values reached");
}

eval { Graph::Layout::Aesthetic->new };
like($@, qr!topology is undefined at !i, "Must have a topology argument");

$topo_destroys = 0;
my $topo3 = Graph::Layout::Aesthetic::Topology->new_vertices(3);
$topo3->add_edge(0, 1);
$topo3->add_edge(1, 2);
$topo3->add_edge(2, 0);
eval { Graph::Layout::Aesthetic->new($topo3) };
like($@, qr!Topology hasn.t been finished at !, "Topology must be finished");
$topo3->finish;
eval { Graph::Layout::Aesthetic->new($topo3, -1) };
    like($@, qr!Nr_dimensions must not be negative at!, "Positive dimensionality");

my $aglo = Graph::Layout::Aesthetic->new($topo3);
isa_ok($aglo, "Graph::Layout::Aesthetic", "Created into the right class");
is($aglo->nr_dimensions, 2, "Defaults to two dimensions");
nearly($aglo->temperature, 1e2, "Default temperature is 1e2");
nearly($aglo->end_temperature, 1e-3, "Default end_temperature is 1e-3");
is($aglo->iterations, 1e3, "Default temperature is 1e3");
is($aglo->topology, $topo3, "Topology is available");
$topo3 = undef;
is($topo_destroys, 0, "aglo keeps topology alive");
$force_destroys = 0;
my $force = Graph::Layout::Aesthetic::Force::NodeRepulsion->new;
is($force_destroys, 0, "The force is alive");
$aglo->_add_force($force);
is($force_destroys, 0, "The force is alive");
$force = undef;
is($force_destroys, 0, "The force is alive");
$destroys = 0;
$aglo = undef;
is($destroys, 1, "Cleanup on last reference");
is($topo_destroys, 1, "Toplogy Cleanup on last reference");
is($force_destroys, 1, "The force is gone");

# Recreate topology
$topo_destroys = 0;
$topo3 = Graph::Layout::Aesthetic::Topology->new_vertices(3);
$topo3->add_edge(0, 1);
$topo3->add_edge(1, 2);
$topo3->add_edge(2, 0);
$topo3->finish;

# Play with forces
$aglo = Graph::Layout::Aesthetic->new($topo3, 3);
is($aglo->nr_dimensions, 3, "New listens to nr_dimensions argument");
$aglo = Graph::Layout::Aesthetic->new($topo3, undef);
is($aglo->nr_dimensions, 2, "Undef means two dimensions");
$force_destroys = 0;
$force = Graph::Layout::Aesthetic::Force::NodeRepulsion->new;
$aglo->_add_force($force);
$force = undef;
is($force_destroys, 0, "The force is alive");
$aglo->clear_forces;
is($force_destroys, 1, "The force is dead");
$force_destroys = 0;
my $force1 = Graph::Layout::Aesthetic::Force::NodeRepulsion->new;
$aglo->_add_force($force1);
$force1 = undef;
my $force2 = Graph::Layout::Aesthetic::Force::MinEdgeLength->new;
$aglo->_add_force($force2, 2);
$force2 = undef;
is($force_destroys, 0, "The force is alive");
my @forces = $aglo->forces;
is(@forces, 2, "Two forces");
isa_ok($forces[0][0], "Graph::Layout::Aesthetic::Force::MinEdgeLength",
       "Right force type");
is(@{$forces[0]}, 2, "Two element force members");
is($forces[0][1], 2, "Right weight");
isa_ok($forces[1][0], "Graph::Layout::Aesthetic::Force::NodeRepulsion",
       "Right force type");
is($forces[1][1], 1, "Right default weight");
KillRef->test($forces[0]);
@forces = ();
is($force_destroys, 0, "The force is alive");

my $forces = $aglo->forces;
is(@$forces, 2, "Two forces");
isa_ok($forces->[0][0], "Graph::Layout::Aesthetic::Force::MinEdgeLength",
       "Right force type");
is(@{$forces->[0]}, 2, "Two element force members");
is($forces->[0][1], 2, "Right weight");
isa_ok($forces->[1][0], "Graph::Layout::Aesthetic::Force::NodeRepulsion",
       "Right force type");
is($forces->[1][1], 1, "Right default weight");
KillRef->test($forces->[0]);
KillRef->test($forces);

is($force_destroys, 0, "The force is alive");
$aglo = undef;
is($force_destroys, 2, "The force is dead");

# Check cleanup on the list form of forces
$aglo = Graph::Layout::Aesthetic->new($topo3, 3);
$force_destroys = 0;
$force1 = Graph::Layout::Aesthetic::Force::NodeRepulsion->new;
$aglo->_add_force($force1);
$force1 = undef;
$force2 = Graph::Layout::Aesthetic::Force::MinEdgeLength->new;
$aglo->_add_force($force2, 2);
$force2 = undef;
is($force_destroys, 0, "The force is alive");
@forces = $aglo->forces;

$destroys = 0;
$aglo = undef;
is($destroys, 1, "Cleanup on last reference");

is($force_destroys, 0, "The force is alive");
@forces = 0;
is($force_destroys, 2, "The force is alive");

# Check cleanup on the scalar form of forces
$aglo = Graph::Layout::Aesthetic->new($topo3, 3);
$force_destroys = 0;
$force1 = Graph::Layout::Aesthetic::Force::NodeRepulsion->new;
$aglo->_add_force($force1);
$force1 = undef;
$force2 = Graph::Layout::Aesthetic::Force::MinEdgeLength->new;
$aglo->_add_force($force2, 2);
$force2 = undef;
is($force_destroys, 0, "The force is alive");
$forces = $aglo->forces;

$destroys = 0;
$aglo = undef;
is($destroys, 1, "Cleanup on last reference");

is($force_destroys, 0, "The force is alive");
$forces = undef;
is($force_destroys, 2, "The force is alive");

$force_destroys = 0;
$aglo = Graph::Layout::Aesthetic->new($topo3, 3);
eval { $aglo->_add_force(undef) };
like($@, qr!force is undefined at !i, "Proper error message");
eval { $aglo->add_force };
like($@, qr!No force name at !, "Proper error message");
$aglo->add_force("NodeRepulsion");
$aglo->add_force(min_edge_length => 5);
@forces = $aglo->forces;
isa_ok($forces[0][0], "Graph::Layout::Aesthetic::Force::MinEdgeLength",
       "Right force type");
is($forces[0][1], 5, "Right weight");
isa_ok($forces[1][0], "Graph::Layout::Aesthetic::Force::NodeRepulsion",
       "Right force type");
is($forces[1][1], 1, "Right default weight");
$destroys = 0;
$aglo = undef;
is($destroys, 1, "Cleanup on last reference");
is($force_destroys, 0, "Manager keeps forces alive");

# Getting and setting coordinates
$aglo = Graph::Layout::Aesthetic->new($topo3);
eval { $aglo->coordinates };
like($@, qr!Usage: Graph::Layout::Aesthetic::coordinates\(state, vertex, \.\.\.\) at !,
     "Right error message");
eval { $aglo->coordinates(3) };
like($@, qr!Vertex number 3 is invalid, there are only 3 in the topology at !,
     "Right error message");
eval { $aglo->coordinates(0, 1) };
like($@, qr!Expected 2 coordinates \(dimension\), but got 1 at !,
     "Right error message");
$aglo->coordinates(0, 1, 2);
is_deeply([$aglo->coordinates(0)], [1, 2], "Right coordinates");
my $coords = $aglo->coordinates(0);
is_deeply($coords, [1, 2], "Right coordinates");
KillRef->test($coords);
is_deeply([$aglo->coordinates(0, [5, 6])], [1, 2], "Right coordinates");
is_deeply([$aglo->coordinates(0)], [5, 6], "Right coordinates");
eval { $aglo->coordinates(0, []) };
like($@, qr!Expected 2 coordinates \(dimension\), but got 0 at !,
     "Right error message");
eval { $aglo->coordinates(0, {}) };
like($@, qr!Coordinates reference is not an array reference at !,
     "Right error message");

my @hole; $hole[1]=5;
eval { $aglo->coordinates(0, \@hole) };
like($@, qr!Vertex 0, coordinate 0 is unset at !, "Right error message");

my (@magic_array1, @magic_array2);
tie @magic_array1, "MagicArray", 3, 8;
tie @magic_array2, "MagicArray", 4, 9;
$aglo->coordinates(0, @magic_array1);
is_deeply(scalar $aglo->coordinates(0), [3, 8], "tied access works");
$aglo->coordinates(0, \@magic_array2);
is_deeply(scalar $aglo->coordinates(0), [4, 9], "tied reference access works");

# Getting and setting all_coordinates
$aglo->coordinates(0, 3, 4);
$aglo->coordinates(1, 5, 6);
$aglo->coordinates(2, 7, 8);
my @coords = $aglo->all_coordinates;
is_deeply(\@coords, [[3, 4], [5, 6], [7, 8]], "List query coordinates works");
KillRef->test($coords[0]);
$coords = $aglo->all_coordinates;
is_deeply($coords, [[3, 4], [5, 6], [7, 8]], "Scalar query coordinates works");
KillRef->test($coords->[0]);
KillRef->test($coords);

$aglo->all_coordinates([9, 10], [11, 12], [13, 14]);
is_deeply(scalar $aglo->all_coordinates, [[9, 10], [11, 12], [13, 14]],
          "List set coordinates works");

$aglo->all_coordinates([[15, 16], [17, 18], [19, 20]]);
is_deeply(scalar $aglo->all_coordinates, [[15, 16], [17, 18], [19, 20]],
          "Array reference set coordinates works");

is_deeply(scalar $aglo->all_coordinates([21, 22], [23, 24], [25, 26]),
          [[15, 16], [17, 18], [19, 20]], "Combined get/set returns old");
is_deeply(scalar $aglo->all_coordinates, [[21, 22], [23, 24], [25, 26]],
          "Combined get/set had effect");
eval { $aglo->all_coordinates(5) };
like($@, qr!First coordinate is not a reference at !, "Right error message");
eval { $aglo->all_coordinates({}) };
like($@, qr!First coordinate is not an array reference at !,
     "Right error message");
eval { $aglo->all_coordinates([]) };
like($@,
     qr!Expected 3 coordinate references \(number of vertices\), but got 0 at!,
     "Right error message");
my @hole3;
$#hole3=2;
eval { $aglo->all_coordinates(\@hole3) };
like($@, qr!Vertex 0 is unset at !, "Right error message");
eval { $aglo->all_coordinates([1, 2, 3]) };
like($@, qr!Vertex 0 is not a reference at !, "Right error message");
eval { $aglo->all_coordinates([{}, 2, 3]) };
like($@, qr!Vertex 0 is not an array reference at !, "Right error message");
eval { $aglo->all_coordinates([[], 2, 3]) };
like($@,
     qr!Vertex 0 has 0 coordinates, but I expected 2 \(the dimension\) at !,
     "Right error message");
eval { $aglo->all_coordinates([\@hole, 2, 3]) };
like($@, qr!Vertex 0, coordinate 0 is unset at !, "Right error message");
eval { $aglo->all_coordinates(1, 2) };
like($@, qr!Expected 3 coordinate references \(number of vertices\), but got 2 at !, "Right error message");
eval { $aglo->all_coordinates(1, 2, 3) };
like($@, qr!Vertex 0 is not a reference at !, "Right error message");
eval { $aglo->all_coordinates({}, 2, 3) };
like($@, qr!Vertex 0 is not an array reference at !, "Right error message");
eval { $aglo->all_coordinates([], 2, 3) };
like($@,
     qr!Vertex 0 has 0 coordinates, but I expected 2 \(the dimension\) at !,
     "Right error message");
eval { $aglo->all_coordinates(\@hole, 2, 3) };
like($@, qr!Vertex 0, coordinate 0 is unset at !, "Right error message");

my $topo1 = Graph::Layout::Aesthetic::Topology->new_vertices(1);
$topo1->finish;
$aglo = Graph::Layout::Aesthetic->new($topo1, 1);
my @hole1;
$#hole1 = 0;
eval { $aglo->all_coordinates(\@hole1) };
like($@, qr!Vertex 0 is unset at !, "Right error message");
eval { $aglo->all_coordinates([{}]) };
like($@, qr!Vertex 0 is not an array reference at !, "Right error message");
eval { $aglo->all_coordinates([[]]) };
like($@,
     qr!Vertex 0 has 0 coordinates, but I expected 1 \(the dimension\) at !,
     "Right error message");
eval { $aglo->all_coordinates([\@hole1]) };
like($@, qr!Vertex 0, coordinate 0 is unset at !, "Right error message");
$aglo->all_coordinates([5]);
is_deeply(scalar $aglo->all_coordinates, [[5]], "1/1 list set");
$aglo->all_coordinates([[6]]);
is_deeply(scalar $aglo->all_coordinates, [[6]], "1/1 reference set");

$aglo = Graph::Layout::Aesthetic->new($topo1, 2);
$aglo->all_coordinates([3, 4]);
is_deeply(scalar $aglo->all_coordinates, [[3, 4]], "Set through COORD goto");
eval { $aglo->all_coordinates([3, 4, 5]) };
like($@,
     qr!Vertex 0 has 3 coordinates, but I expected 2 \(the dimension\) at !,
     "Right message after COORD goto");
eval { $aglo->all_coordinates(\@hole) };
like($@, qr!Vertex 0, coordinate 0 is unset at !,
     "Right message after COORD goto");

# Check increasing_edges
$aglo = Graph::Layout::Aesthetic->new($topo3);
$aglo->all_coordinates([3, 4], [5, 6], [7, 8]);
my @edges = $aglo->increasing_edges;
is_deeply(\@edges, [[[3, 4], [7, 8]], [[3, 4], [5, 6]], [[5, 6], [7,8]]],
          "Increasing edges");
KillRef->test($edges[0][0]);
KillRef->test($edges[0]);

my $edges = $aglo->increasing_edges;
is_deeply($edges, [[[3, 4], [7, 8]], [[3, 4], [5, 6]], [[5, 6], [7,8]]],
          "Increasing edges");
KillRef->test($edges->[0][0]);
KillRef->test($edges->[0]);
KillRef->test($edges);

# Check zero
$aglo = Graph::Layout::Aesthetic->new($topo3);
$aglo->all_coordinates([3, 4], [5, 6], [7, 8]);
$aglo->zero;
is_deeply(scalar $aglo->all_coordinates, [[0, 0], [0,0], [0, 0]],
          "Zeroed all coordinates");

# Check randomize
$aglo = Graph::Layout::Aesthetic->new($topo3);
$aglo->all_coordinates([3, 4], [5, 6], [7, 8]);
$aglo->randomize;
for ($aglo->all_coordinates) {
    for (@$_) {
        ok($_ <  1, "Coordinate below 1");
        ok($_ > -1, "Coordinate above 0");
    }
}
is_random($aglo, sub {
    $_[0]->randomize($_[1]);
});
# Default randomize is 1
is_random($aglo, sub {
    $_[0]->randomize;
    my @coords = $aglo->all_coordinates;
    for (@coords) {
        $_ *= $_[1] for @$_;
    }
    $aglo->all_coordinates(@coords);
});

# Check jitter
$aglo = Graph::Layout::Aesthetic->new($topo3);
$aglo->zero;
$aglo->jitter;
my $sum = 0;
for ($aglo->all_coordinates) {
    $sum+= $_*$_ for @$_;
}
ok($sum > 0, "There was a displacement");
ok($sum < 1e-5, "But not too big");
is_random($aglo, sub {
    $_[0]->zero;
    $_[0]->jitter($_[1]);
});
# Default jitter is 1e-5
is_random($aglo, sub {
    $_[0]->zero;
    $_[0]->jitter;
    my @coords = $aglo->all_coordinates;
    for (@coords) {
        $_ *= $_[1]/1e-5 for @$_;
    }
    $aglo->all_coordinates(@coords);
});

# Checking frame
$aglo = Graph::Layout::Aesthetic->new($topo3);
$aglo->all_coordinates([3, 6], [7, 4], [5, 10]);
is_deeply([$aglo->frame], [[3, 4], [7, 10]], "Right frame");

# Checking iso_frame
$aglo = Graph::Layout::Aesthetic->new($topo3);
$aglo->all_coordinates([3, 6], [7, 4], [5, 10]);
is_deeply([$aglo->iso_frame], [[2, 4], [8, 10]], "Right iso frame");

# Check normalize
$aglo = Graph::Layout::Aesthetic->new($topo3);
$aglo->all_coordinates([3, 6], [7, 4], [5, 12]);
$aglo->normalize;
is_deeply(scalar $aglo->all_coordinates, [[1/4, 1/4], [3/4, 0], [1/2, 1]],
          "Right normalization");

# Checking init_gloss
$aglo = Graph::Layout::Aesthetic->new($topo3);
$aglo->zero;
$aglo->init_gloss(2, 1, 3, -1);
is($aglo->temperature, 2, "Temperature set");
is($aglo->end_temperature, 1, "End temperature set");
is($aglo->iterations, 3, "Iterations set");
is_deeply(scalar $aglo->all_coordinates, [[0, 0], [0, 0], [0, 0]],
          "Vertices unmoved");
# Randomize if given
is_random($aglo, sub {
    $_[0]->zero;
    $_[0]->init_gloss(2, 1, 3, $_[1]);
});
# Default randomize is 1
is_random($aglo, sub {
    $_[0]->zero;
    $_[0]->init_gloss(2, 1, 3);
    my @coords = $aglo->all_coordinates;
    for (@coords) {
        $_ *= $_[1] for @$_;
    }
    $aglo->all_coordinates(@coords);
});
eval { $aglo->init_gloss(2, 1, -1) };
like($@, qr!Iterations -1 should be >= 0 at !,
     "Iterations must be non-negative");
eval { $aglo->init_gloss(0, 1, 1) };
like($@, qr!Temperature 0\.0+ should be > 0 at !,
     "Temperature must be positive");
eval { $aglo->init_gloss(1, 0, 1) };
like($@, qr!End_temperature 0\.0+ should be > 0 at !,
     "End_temperature must be positive");
check_warnings;
$aglo->init_gloss(1, 2, 1);
is(@warnings, 1, "One warning");
like($warnings[0],
     qr!Temperature 1\.0+ should probably be >= end_temperature 2\.0+ at !,
     "Temperature should decrease");
@warnings = ();

# Checking step
# If there are nor forces, step is jitter
$aglo = Graph::Layout::Aesthetic->new($topo3);
$aglo->zero;
$aglo->step;
$sum = 0;
for ($aglo->all_coordinates) {
    $sum+= $_*$_ for @$_;
}
ok($sum > 0, "There was a displacement");
ok($sum < 1e-5, "But not too big");
is_random($aglo, sub {
    $_[0]->zero;
    $_[0]->step(100, $_[1]);
});
# Default jitter is 1e-5
is_random($aglo, sub {
    $_[0]->zero;
    $_[0]->step;
    my @coords = $aglo->all_coordinates;
    for (@coords) {
        $_ *= $_[1]/1e-5 for @$_;
    }
    $aglo->all_coordinates(@coords);
});
is($aglo->iterations, 1000, "Iterations unchanged by step");
is($aglo->temperature, 1e2, "Temperature unchanged by step");
# Default jitter is 1e-5, but temperature restricted
is_random($aglo, sub {
    $_[0]->zero;
    $_[0]->step(1e-6);
    my @coords = $aglo->all_coordinates;
    for (@coords) {
        $_ *= $_[1]/1e-6 for @$_;
    }
    $aglo->all_coordinates(@coords);
});
is($aglo->temperature, 1e2,
   "Temperature unchanged by explicite temperature step");
$aglo->zero;
$aglo->step(100, 0);
is_deeply(scalar $aglo->all_coordinates, [[0, 0], [0,0], [0, 0]],
          "All coordinates remain zero");

# Combine step checking and gradient checking
my $topo2 = Graph::Layout::Aesthetic::Topology->new_vertices(2);
$topo2->add_edge(0, 1);
$topo2->finish;
$aglo = Graph::Layout::Aesthetic->new($topo2);
$aglo->add_force("min_edge_length");
$aglo->all_coordinates([0, -1], [0, 1]);
my @gradient = $aglo->gradient;
is_deeply(\@gradient, [[0, 4], [0, -4]], "Quadratic attraction");
KillRef->test($gradient[0]);
my $gradient = $aglo->gradient;
is_deeply($gradient, [[0, 4], [0, -4]], "Quadratic attraction");
KillRef->test($gradient->[0]);
KillRef->test($gradient);
# Now let the gradient work on the given state
$aglo->step(10, 0);
is_deeply(scalar $aglo->all_coordinates, [[0, 3], [0, -3]]);
$aglo->all_coordinates([0, -1], [0, 1]);
$aglo->step(4, 0);
@coords = $aglo->all_coordinates;
is($coords[0][0], 0);
nearly($coords[0][1], -1+4/sqrt 2, "Temperature restricted");
is($coords[1][0], 0);
nearly($coords[1][1], 1-4/sqrt 2, "Temperature restricted");
# Try along the other axis too
$aglo->all_coordinates([0, -1], [0, 1]);
my $tries = 1000;
while ($tries > 0) {
    $tries++;
    $aglo->step;
    last if $aglo->coordinates(0)->[0];
}
ok($tries, "Sometimes we jitter off the axis");
$aglo->all_coordinates([-1, 0], [1, 0]);
is_deeply(scalar $aglo->gradient, [[4, 0], [-4, 0]]);
$aglo->step(10, 0);
is_deeply(scalar $aglo->all_coordinates, [[3, 0], [-3, 0]]);
$aglo->clear_forces;
is_deeply(scalar $aglo->gradient, [[0, 0], [0, 0]]);

$aglo->all_coordinates([-1, 0], [1, 0]);
$aglo->add_force("min_edge_length", 1/2);
is_deeply(scalar $aglo->gradient, [[2, 0], [-2, 0]]);
$aglo->step(10, 0);
is_deeply(scalar $aglo->all_coordinates, [[1, 0], [-1, 0]], "Half step");
# Additive force....
$aglo->all_coordinates([-1, 0], [1, 0]);
$aglo->add_force("min_edge_length", 3/2);
is_deeply(scalar $aglo->gradient, [[8, 0], [-8, 0]]);
$aglo->step(12, 0);
is_deeply(scalar $aglo->all_coordinates, [[7, 0], [-7, 0]], "Double step");

# Checking stress
$aglo = Graph::Layout::Aesthetic->new($topo2);
$aglo->add_force("min_edge_length");
$aglo->all_coordinates([0, -1], [0, 1]);
is_deeply(scalar $aglo->gradient, [[0, 4], [0, -4]], "Quadratic attraction");
nearly($aglo->stress, 4*sqrt 2, "Stressed out");

# Checking _gloss
$aglo = Graph::Layout::Aesthetic->new($topo2);
$aglo->add_force("min_edge_length");
$aglo->all_coordinates([0, -1], [0, 1]);
$aglo->_gloss(0);
is($aglo->iterations, 999, "Iterations lowered");
nearly($aglo->temperature, 100 / (100/1e-3)**(1/1000), "Temperature lowered");
nearly($aglo->end_temperature, 1e-3, "End_temperature unchanged");
{
    local $EPS = 1e-4;
    @coords = $aglo->all_coordinates;
    nearly($coords[0][0], 0);
    nearly($coords[0][1], 3);
    nearly($coords[1][0], 0);
    nearly($coords[1][1],-3);
}
$aglo->all_coordinates([0, -1], [0, 1]);
$aglo->init_gloss(100, 1, 1, 0);
$aglo->_gloss();
is($aglo->iterations, 0, "Iterations lowered");
nearly($aglo->temperature, 1, "Temperature lowered");
nearly($aglo->end_temperature, 1, "End_temperature unchanged");
{
    local $EPS = 1e-4;
    @coords = $aglo->all_coordinates;
    nearly($coords[0][0], 0);
    nearly($coords[0][1], 3);
    nearly($coords[1][0], 0);
    nearly($coords[1][1],-3);
}
$aglo->end_temperature(1e-3);
eval { $aglo->_gloss() };
like($@, qr!No more iterations left at !, "Can't iterate beyond 0");
is($aglo->iterations, 0, "Iterations unchanged");
nearly($aglo->temperature, 1, "Temperature unchanged");

$aglo->add_force("node_repulsion");
$aglo->all_coordinates([0, -1], [0, 1]);
$aglo->init_gloss(100, 1e-3, 1000, 0);
$aglo->_gloss(time);
is($aglo->iterations, 999, "Time based finish");
$aglo->_gloss(10000+time);
is($aglo->iterations, 0, "Enough time to finish");
@coords = $aglo->all_coordinates;
my $distance = sqrt(($coords[0][0]-$coords[1][0])**2 +
                    ($coords[0][1]-$coords[1][1])**2);
{
    local $EPS = 2e-2;
    nearly($distance, 1, "Balance");
    nearly($aglo->stress, 0, "Balance");
}
$aglo->all_coordinates([0, -1], [0, 1]);
$aglo->init_gloss(100, 1e-3, 1000, 0);
$aglo->_gloss();
is($aglo->iterations, 0, "Enough time to finish");
@coords = $aglo->all_coordinates;
$distance = sqrt(($coords[0][0]-$coords[1][0])**2 +
                 ($coords[0][1]-$coords[1][1])**2);
{
    local $EPS = 2e-2;
    nearly($distance, 1, "Balance");
    nearly($aglo->stress, 0, "Balance");
}

# Checking gloss
$aglo = Graph::Layout::Aesthetic->new($topo3);
is_random($aglo, sub {
    # One-step gloss without forces and hold is just a randomize
    $aglo->all_coordinates([3, 6], [7, 4], [5, 10]);
    $aglo->gloss(iterations => 1);
    my @coords = $aglo->all_coordinates;
    for (@coords) {
        $_ *= $_[1] for @$_;
    }
    $aglo->all_coordinates(@coords);
});

$aglo = Graph::Layout::Aesthetic->new($topo2);
$aglo->add_force("min_edge_length");
$aglo->all_coordinates([0, -1], [0, 1]);
$aglo->end_temperature(1);
$aglo->gloss(iterations => 1, hold => 1);
is($aglo->iterations, 0, "Iterations lowered");
nearly($aglo->temperature, 1e-3, "Temperature lowered");
nearly($aglo->end_temperature, 1e-3, "End_temperature unchanged");
{
    local $EPS = 1e-4;
    @coords = $aglo->all_coordinates;
    nearly($coords[0][0], 0);
    nearly($coords[0][1], 3);
    nearly($coords[1][0], 0);
    nearly($coords[1][1],-3);
}

$aglo->all_coordinates([0, -1], [0, 1]);
$aglo->gloss(begin_temperature => 4, iterations => 1, hold => 1);
@coords = $aglo->all_coordinates;
{
    local $EPS = 1e-4;
    nearly($coords[0][0], 0);
    nearly($coords[0][1], -1+4/sqrt 2, "Temperature restricted");
    nearly($coords[1][0], 0);
    nearly($coords[1][1], 1-4/sqrt 2, "Temperature restricted");
}

$aglo->add_force("node_repulsion");
$aglo->all_coordinates([0, -1], [0, 1]);
$aglo->gloss(hold => 1, end_temperature => 2e-3);
is($aglo->iterations, 0, "Enough time to finish");
nearly($aglo->temperature,     2e-3, "Temperature lowered");
nearly($aglo->end_temperature, 2e-3, "End_temperature reached");
@coords = $aglo->all_coordinates;
$distance = sqrt(($coords[0][0]-$coords[1][0])**2 +
                    ($coords[0][1]-$coords[1][1])**2);
{
    local $EPS = 2e-2;
    nearly($distance, 1, "Balance");
    nearly($aglo->stress, 0, "Balance");
}
eval { $aglo->gloss(foo => 5) };
like($@, qr!Unknown parameter foo at !, "Right error message");
# Accepts iterations 0
$aglo->gloss(iterations => 0);
$aglo->gloss(iterations => 0, monitor => sub {});

# Test monitor CODE ref
$count = 0;
$aglo->gloss(monitor_delay => 10000, monitor => sub { $count++ });
is($count, 2, "Begin and end call");

# Test monitor object
$count = 0;
$aglo->gloss(monitor_delay => 10000, monitor => TestMonitor->new);
is($count, 2, "Begin and end call");
is($monitors, 0, "Monitor got freed again");

$count = 0;
$aglo->gloss(monitor_delay => 0, monitor => sub { $count++ });
is($count, 1001, "Begin and end call and all inbetweens");
$distance = sqrt(($coords[0][0]-$coords[1][0])**2 +
                 ($coords[0][1]-$coords[1][1])**2);
{
    local $EPS = 2e-2;
    nearly($distance, 1, "Balance");
    nearly($aglo->stress, 0, "Balance");
}

# Checking temperature
$aglo = Graph::Layout::Aesthetic->new($topo3);
is($aglo->temperature, 100, "Right default temperature");
$aglo->temperature(1000);
is($aglo->temperature, 1000, "Right temperature setting");
is($aglo->temperature(500), 1000, "Combined temperature get/set");
is($aglo->temperature, 500, "Right value after get/set");
eval { $aglo->temperature(0) };
like($@, qr!Temperature 0\.0+ should be > 0 at !,
     "Temperature must be positive");
is($aglo->temperature, 500, "Unchanged on failure");
is($aglo->temperature(1e-4, 0), 500, "Combined get, but set below end");
check_warnings;
nearly($aglo->temperature(2e-4, 1), 1e-4, "Combined get, but set below end");
is(@warnings, 1, "One warning");
like($warnings[0], qr!Temperature 0\.00020* should probably be >= end_temperature 0\.0010* at!, "Proper warning");
@warnings = ();
nearly($aglo->temperature(3e-4), 2e-4, "Combined get, but set below end");
is(@warnings, 1, "One warning");
like($warnings[0], qr!Temperature 0\.00030* should probably be >= end_temperature 0\.0010* at!, "Proper warning");
@warnings = ();
nearly($aglo->temperature, 3e-4, "Combined get, but set below end");

# Checking end_temperature
$aglo = Graph::Layout::Aesthetic->new($topo3);
nearly($aglo->end_temperature, 1e-3, "Right default temperature");
$aglo->end_temperature(1);
is($aglo->end_temperature, 1, "Right temperature setting");
is($aglo->end_temperature(2), 1, "Combined temperature get/set");
is($aglo->end_temperature, 2, "Right value after get/set");
eval { $aglo->end_temperature(0) };
like($@, qr!End_temperature 0\.0+ should be > 0 at !,
     "End_temperature must be positive");
is($aglo->end_temperature, 2, "Unchanged on failure");
is($aglo->end_temperature(500, 0), 2, "Combined get, but set above current");
check_warnings;
nearly($aglo->end_temperature(200, 1), 500, "Combined get, but set below end");
is(@warnings, 1, "One warning");
like($warnings[0], qr!Temperature 100\.0+ should probably be >= end_temperature 200\.0+ at !, "Proper warning");
@warnings = ();
nearly($aglo->end_temperature(300), 200, "Combined get, but set below end");
is(@warnings, 1, "One warning");
like($warnings[0], qr!Temperature 100\.0+ should probably be >= end_temperature 300\.0+ at !, "Proper warning");
@warnings = ();
nearly($aglo->end_temperature, 300, "Combined get, but set below end");

# Checking iterations
$aglo = Graph::Layout::Aesthetic->new($topo3);
is($aglo->iterations, 1000, "Proper default");
$aglo->iterations(100);
is($aglo->iterations, 100, "Settable");
is($aglo->iterations(200), 100, "Combined get/set");
is($aglo->iterations, 200, "Value changed");
eval { $aglo->iterations(-1) };
like($@, qr!Iterations -1 should be >= 0 at !, "Proper error message");
is($aglo->iterations, 200, "Value unchanged on error");

# Checking pause
$aglo = Graph::Layout::Aesthetic->new($topo3);
is($aglo->paused, "", "The default is unpaused");
is($aglo->paused, "", "Paused without args doesn't change a false state");
$aglo->pause;
is($aglo->paused, 1, "Pause sets the pause flag");
is($aglo->paused, 1, "Paused without args doesn't change a false state");
$aglo->pause;
is($aglo->paused, 1, "Pause is idempotent");
is($aglo->paused("foo"), 1, "Combined assign returns old value");
is($aglo->paused, 1, "Everything true is equivalent");
is($aglo->paused(undef), 1, "Combined assign returns old value");
is($aglo->paused(0), "", "Undef is false");
is($aglo->paused(""), "", "0 is false");
is($aglo->paused, "", "\"\" is false");

# The corresponding tests for _gloss will be done in the perl force tester
# since we need a gradient callback for them
for my $start_pause (0, 1) {
    my $count = 0;
    $aglo->paused($start_pause);
    $aglo->gloss(iterations => 3,
                 monitor_delay => 0,
                 monitor => sub {
                     is($aglo->paused, "");
                     $count++;
                 });
    is($count, 4, "Done all counts");
    is($aglo->paused, "");

    for $_ (0..3) {
        my $count = 0;
        $aglo->paused($start_pause);
        $aglo->gloss(iterations => 3,
                     monitor_delay => 0,
                     monitor => sub {
                         my $aglo = shift;
                         is($aglo->paused, "");
                         $aglo->pause if $count == $_;
                         $count++;
                     });
        is($count, $_+1, "Done only start event");
        is($aglo->iterations, 3-$_, "No iterations done");
        is($aglo->paused, 1);
    }
}

can_ok("Graph::Layout::Aesthetic", qw(coordinates_to_graph gloss_graph));

my $graph_class = eval "use Graph; 1" ? "Graph" : undef;

if ($graph_class && $Graph::VERSION >= 0.50) {
    # Check coordinates_to_graph
    my $g = $graph_class->new;
    $g->add_edge("foo0", "foo1");
    $g->add_edge("foo0", "foo2");
    $g->add_edge("foo2", "foo0");
    $g->add_edge("foo2", "foo3");
    $g->add_edge("foo3", "foo3");

    my $t = Graph::Layout::Aesthetic::Topology->from_graph
        ($g, id_attribute => undef);
    is($t->nr_vertices, 4);
    $aglo = Graph::Layout::Aesthetic->new($t);
    $aglo->all_coordinates([1, 2], [3, 4], [5, 6], [7, 8]);
    $g->set_vertex_attribute("foo0", "index", 3);
    $g->set_vertex_attribute("foo1", "index", 2);
    $g->set_vertex_attribute("foo2", "index", 0);
    $g->set_vertex_attribute("foo3", "index", 1);

    ok(!$g->has_vertex_attribute("foo0", "foo"));
    ok(!$g->has_graph_attribute("bar"));
    ok(!$g->has_graph_attribute("baz"));
    $aglo->coordinates_to_graph($g,
                                pos_attribute => "foo",
                                min_attribute => "bar",
                                max_attribute => "baz",
                                id_attribute  => "index");
    is_deeply($g->get_vertex_attribute("foo0", "foo"), [7, 8]);
    is_deeply($g->get_vertex_attribute("foo1", "foo"), [5, 6]);
    is_deeply($g->get_vertex_attribute("foo2", "foo"), [1, 2]);
    is_deeply($g->get_vertex_attribute("foo3", "foo"), [3, 4]);
    is_deeply($g->get_graph_attribute("bar"), [1, 2]);
    is_deeply($g->get_graph_attribute("baz"), [7, 8]);

    ok(!$g->get_vertex_attribute("foo0", "x"));
    ok(!$g->get_graph_attribute($_)) for qw(i j k l);
    $aglo->coordinates_to_graph($g,
                                pos_attribute => ["x", "y"],
                                min_attribute => ["i", "j"],
                                max_attribute => ["k", "l"],
                                id_attribute => "index");
    is($g->get_vertex_attribute("foo0", "x"), 7);
    is($g->get_vertex_attribute("foo0", "y"), 8);
    is($g->get_vertex_attribute("foo1", "x"), 5);
    is($g->get_vertex_attribute("foo1", "y"), 6);
    is($g->get_vertex_attribute("foo2", "x"), 1);
    is($g->get_vertex_attribute("foo2", "y"), 2);
    is($g->get_vertex_attribute("foo3", "x"), 3);
    is($g->get_vertex_attribute("foo3", "y"), 4);
    is($g->get_graph_attribute("i"), 1);
    is($g->get_graph_attribute("j"), 2);
    is($g->get_graph_attribute("k"), 7);
    is($g->get_graph_attribute("l"), 8);

    eval { $aglo->coordinates_to_graph($g,
                                       pos_attribute => ["x", "y"],
                                       id_attribute  => "zoem") };
    like($@, qr!^Vertex 'foo\d' has no 'zoem' attribute at !);
    eval { $aglo->coordinates_to_graph($g,
                                       pos_attribute => "layout_pos",
                                       id_attribute  => "zoem") };
    like($@, qr!^Vertex 'foo\d' has no 'zoem' attribute at !);
    eval { $aglo->coordinates_to_graph($g, pos_attribute => "layout_pos") };
    like($@, qr!^Vertex 'foo\d' has no 'layout_id' attribute at !,
         "Default id attribute is aglo");
    eval { $aglo->coordinates_to_graph($g,
                                       pos_attribute => "layout_pos",
                                       id_attribute  => undef) };
    like($@, qr!^Vertex 'foo\d' has no 'layout_id' attribute at !,
         "Default id attribute is layout_id");
    eval { $aglo->coordinates_to_graph($g,
                                       grmbl => "layout_pos") };
    like($@, qr!^Unknown parameter grmbl at !,
         "Attributes get properly checked");

    $g->set_vertex_attribute("foo0", "layout_id", 3);
    $g->set_vertex_attribute("foo1", "layout_id", 2);
    $g->set_vertex_attribute("foo2", "layout_id", 1);
    $g->set_vertex_attribute("foo3", "layout_id", 0);
    $aglo->coordinates_to_graph($g, pos_attribute => "foo");
    is_deeply($g->get_vertex_attribute("foo0", "foo"), [7, 8]);
    is_deeply($g->get_vertex_attribute("foo1", "foo"), [5, 6]);
    is_deeply($g->get_vertex_attribute("foo2", "foo"), [3, 4]);
    is_deeply($g->get_vertex_attribute("foo3", "foo"), [1, 2]);

    ok(!$g->has_vertex_attribute("foo0", "layout_pos"));
    $g->delete_graph_attribute("layout_min");
    $g->delete_graph_attribute("layout_max");
    $aglo->coordinates_to_graph($g);
    is_deeply($g->get_vertex_attribute("foo0", "layout_pos"), [7, 8]);
    is_deeply($g->get_vertex_attribute("foo1", "layout_pos"), [5, 6]);
    is_deeply($g->get_vertex_attribute("foo2", "layout_pos"), [3, 4]);
    is_deeply($g->get_vertex_attribute("foo3", "layout_pos"), [1, 2]);
    is_deeply($g->get_graph_attribute("layout_min"), [1, 2]);
    is_deeply($g->get_graph_attribute("layout_max"), [7, 8]);

    for my $v ($g->vertices) {
        $g->delete_vertex_attribute($v, $_) for
            qw(layout_pos foo x y index layout_id);
    }
    $g->delete_graph_attribute($_) for qw(layout_min layout_max i j k l);
    my %attr = (foo0 => 2, foo1 => 3, foo2 => 1, foo3 => 0);
    ok(!$g->has_vertex_attribute("foo0", "layout_pos"));
    $aglo->coordinates_to_graph($g,
                                pos_attribute => undef,
                                min_attribute => undef,
                                max_attribute => undef,
                                id_attribute  => \%attr);
    ok(!$g->has_vertex_attribute("foo0", "layout_pos"));
    ok(!$g->has_graph_attribute("layout_min"));
    ok(!$g->has_graph_attribute("layout_max"));

    %attr = (foo0 => 2, foo1 => 3, foo2 => 0, foo3 => 1);
    ok(!$g->has_vertex_attribute("foo0", "x1"));
    $aglo->coordinates_to_graph($g,
                                pos_attribute => ["x1", "x2"],
                                id_attribute  => \%attr);
    is($g->get_vertex_attribute("foo0", "x1"), 5);
    is($g->get_vertex_attribute("foo0", "x2"), 6);
    is($g->get_vertex_attribute("foo1", "x1"), 7);
    is($g->get_vertex_attribute("foo1", "x2"), 8);
    is($g->get_vertex_attribute("foo2", "x1"), 1);
    is($g->get_vertex_attribute("foo2", "x2"), 2);
    is($g->get_vertex_attribute("foo3", "x1"), 3);
    is($g->get_vertex_attribute("foo3", "x2"), 4);
    is_deeply($g->get_graph_attribute("layout_min"), [1, 2]);
    is_deeply($g->get_graph_attribute("layout_max"), [7, 8]);

    eval { $aglo->coordinates_to_graph($g,
                                       pos_attribute => [4],
                                       id_attribute  => \%attr) };
    like($@, qr!^Number of entries in the position attribute array must be equal to the number of dimensions at !,
         "Proper dimensionalitry check on attribute");
    eval { $aglo->coordinates_to_graph($g,
                                       min_attribute => [4],
                                       id_attribute  => \%attr) };
    like($@, qr!^Number of entries in the minimum attribute array must be equal to the number of dimensions at !,
         "Proper dimensionalitry check on attribute");
    eval { $aglo->coordinates_to_graph($g,
                                       max_attribute => [4],
                                       id_attribute  => \%attr) };
    like($@, qr!^Number of entries in the maximum attribute array must be equal to the number of dimensions at !,
         "Proper dimensionalitry check on attribute");

    # Check gloss_graph
    $g = $graph_class->new;
    $g->add_edge("foo0", "foo1");
    eval { Graph::Layout::Aesthetic->gloss_graph($g) };
    like($@, qr!^No forces were defined at !);
    eval { Graph::Layout::Aesthetic->gloss_graph($g, forces => undef) };
    like($@, qr!^No forces were defined at !);
    eval { Graph::Layout::Aesthetic->gloss_graph($g,
                                                 forces => {},
                                                 Zoem => 8) };
    like($@, qr!^Unknown parameter Zoem at !, "Bad parameters get recognized");
    eval { Graph::Layout::Aesthetic->gloss_graph($g,
                                                 forces => {},
                                                 hold => "zzz") };
    like($@,
         qr!^Attribute 'zzz' for vertex 'foo\d' is not an array reference at !,
         "Copy attempt if hold given");
    eval { Graph::Layout::Aesthetic->gloss_graph($g,
                                                 forces => {},
                                                 hold => 1) };
    like($@, qr!^Attribute 'layout_pos' for vertex 'foo\d' is not an array reference at !,
         "Copy attempt from layout_pos if hold is 1");
    eval { Graph::Layout::Aesthetic->gloss_graph($g,
                                                 forces => {},
                                                 pos_attribute => "yyy",
                                                 hold => 1) };
    like($@,
         qr!^Attribute 'yyy' for vertex 'foo\d' is not an array reference at !,
         "Copy attempt from layout_pos if hold is 1");

    eval { Graph::Layout::Aesthetic->gloss_graph($g,
                                                 forces => {},
                                                 pos_attribute => ["x", "y"],
                                                 hold => 1) };
    like($@,
         qr!^Attribute 'x' for vertex 'foo\d' doesn.t exist at !,
         "Copy attempt from layout_pos if hold is 1");

    ok(!$g->has_vertex_attribute("layout_pos", "foo0"),
       "No layout_pos attribute yet");
    ok(!$g->has_graph_attribute("layout_min"), "No layout_min attribute yet");
    ok(!$g->has_graph_attribute("layout_max"), "No layout_max attribute yet");
    Graph::Layout::Aesthetic->gloss_graph($g, forces => {}, iterations => 1);
    ok($g->has_vertex_attribute("foo0", "layout_pos"), "Pos attribute now");
    is(@{$g->get_vertex_attribute("foo0", "layout_pos")}, 2,
       "Default 2 dimensions");
    ok($g->has_graph_attribute("layout_min"), "Min attribute now");
    is(@{$g->get_graph_attribute("layout_min")}, 2, "Default 2 dimensions");
    ok($g->has_graph_attribute("layout_max"), "Max attribute now");
    is(@{$g->get_graph_attribute("layout_max")}, 2, "Default 2 dimensions");
    Graph::Layout::Aesthetic->gloss_graph($g,
                                          forces => {},
                                          iterations => 1,
                                          nr_dimensions => 3);
    is(@{$g->get_vertex_attribute("foo0", "layout_pos")}, 3,
       "Three dimensions if requested");
    is(@{$g->get_graph_attribute("layout_min")}, 3,
       "Three dimensions if requested");
    is(@{$g->get_graph_attribute("layout_max")}, 3,
       "Three dimensions if requested");

    # At 0 iterations gloss_graph should behave like init_gloss
    $g->set_vertex_attribute("foo0", "layout_pos", [2, 2]);
    $g->set_graph_attribute("layout_min", [3, 3]);
    $g->set_graph_attribute("layout_max", [4, 4]);
    Graph::Layout::Aesthetic->gloss_graph($g,
                                          forces => {},
                                          iterations => 0);
    for my $pos ($g->get_vertex_attribute("foo0", "layout_pos"),
                 $g->get_graph_attribute("layout_min"),
                 $g->get_graph_attribute("layout_max")) {
        ok(-1 < $pos->[0]);
        ok($pos->[0] < 1);
        ok(-1 < $pos->[1]);
        ok($pos->[1] < 1);
    }

    $g->set_vertex_attribute("foo0", "layout_pos", [2, 3]);
    $g->set_graph_attribute("layout_min", "abba");
    $g->set_graph_attribute("layout_max", {z => 4});
    Graph::Layout::Aesthetic->gloss_graph($g,
                                          forces => {},
                                          iterations => 0,
                                          hold => 1,
                                          min_attribute => undef,
                                          max_attribute => undef);
    is_deeply($g->get_vertex_attribute("foo0", "layout_pos"), [2, 3]);
    is($g->get_graph_attribute("layout_min"), "abba");
    is_deeply($g->get_graph_attribute("layout_max"), {z => 4});

    $g->set_vertex_attribute("foo0", "layout_pos", [4, 5]);
    ok(!$g->has_vertex_attribute("foo0", "www"), "No www attribute yet");
    Graph::Layout::Aesthetic->gloss_graph($g,
                                          forces => {},
                                          iterations => 0,
                                          pos_attribute => "www",
                                          hold => "layout_pos");
    is_deeply($g->get_vertex_attribute("foo0", "www"), [4, 5]);

    g_is_random($g, sub {
        Graph::Layout::Aesthetic->gloss_graph($_[0],
                                              forces => {},
                                              iterations => 0);
    });

    Graph::Layout::Aesthetic->gloss_graph($g,
                                          forces => {
                                              min_edge_length => 1,
                                              node_repulsion  => 1,
                                          });
    $coords[0] = $g->get_vertex_attribute("foo0", "layout_pos");
    $coords[1] = $g->get_vertex_attribute("foo1", "layout_pos");
    $distance = sqrt(($coords[0][0]-$coords[1][0])**2 +
                     ($coords[0][1]-$coords[1][1])**2);
    {
        local $EPS = 2e-2;
        nearly($distance, 1, "Balance");
    }

    $count = 0;
    Graph::Layout::Aesthetic->gloss_graph($g,
                                          forces => {
                                              min_edge_length => 1/4,
                                              node_repulsion  => 2,
                                          },
                                          monitor => sub { $count++},
                                          monitor_delay => 0);
    is($count, 1001, "Default number of iterations");
    $coords[0] = $g->get_vertex_attribute("foo0", "layout_pos");
    $coords[1] = $g->get_vertex_attribute("foo1", "layout_pos");
    $distance = sqrt(($coords[0][0]-$coords[1][0])**2 +
                     ($coords[0][1]-$coords[1][1])**2);
    {
        local $EPS = 2e-2;
        nearly($distance, 2, "Balance");
    }

    if (eval { require Graph::Directed }) {
        my $g = Graph::Directed->new;
        $g->add_edge("foo0", "foo1");
        Graph::Layout::Aesthetic->gloss_graph($g,
                                              literal => 1,
                                              forces => {
                                                  min_edge_length => 1,
                                                  parent_left     => 1,
                                              });
        $coords[0] = $g->get_vertex_attribute("foo0", "layout_pos");
        $coords[1] = $g->get_vertex_attribute("foo1", "layout_pos");
        $distance = sqrt(($coords[0][0]-$coords[1][0])**2 +
                         ($coords[0][1]-$coords[1][1])**2);
        {
            local $EPS = 2e-2;
            nearly($distance, 2.5, "Balance");
        }

        Graph::Layout::Aesthetic->gloss_graph($g,
                                              forces => {
                                                  min_edge_length => 1,
                                                  parent_left     => 1,
                                              });
        $coords[0] = $g->get_vertex_attribute("foo0", "layout_pos");
        $coords[1] = $g->get_vertex_attribute("foo1", "layout_pos");
        $distance = sqrt(($coords[0][0]-$coords[1][0])**2 +
                         ($coords[0][1]-$coords[1][1])**2);
        {
            local $EPS = 2e-2;
            nearly($distance, 2.5, "Balance");
        }

        $g = Graph::Directed->new;
        $g->add_edge("foo0", "foo1");
        $g->add_edge("foo1", "foo0");
        Graph::Layout::Aesthetic->gloss_graph($g,
                                              literal => 1,
                                              forces => {
                                                  min_edge_length => 1,
                                                  parent_left     => 1,
                                              });
        $coords[0] = $g->get_vertex_attribute("foo0", "layout_pos");
        $coords[1] = $g->get_vertex_attribute("foo1", "layout_pos");
        $distance = sqrt(($coords[0][0]-$coords[1][0])**2 +
                         ($coords[0][1]-$coords[1][1])**2);
        {
            local $EPS = 2e-2;
            nearly($distance, 0, "Balance");
        }

        Graph::Layout::Aesthetic->gloss_graph($g,
                                              forces => {
                                                  min_edge_length => 1,
                                                  parent_left     => 1,
                                              });
        $coords[0] = $g->get_vertex_attribute("foo0", "layout_pos");
        $coords[1] = $g->get_vertex_attribute("foo1", "layout_pos");
        $distance = sqrt(($coords[0][0]-$coords[1][0])**2 +
                         ($coords[0][1]-$coords[1][1])**2);
        {
            local $EPS = 2e-2;
            nearly($distance, 2.5, "Balance");
        }
    } else {
        diag("You don't seem to have Graph::Directed. Tests skipped");
    }
} elsif ($graph_class) {
    diag("You have Graph version $Graph::VERSION which is below 0.50. Tests skipped");
} else {
    diag("You don't seem to have a Graph class. Tests skipped");
}
