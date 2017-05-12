#!/usr/bin/perl -w
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 04_Force.t'

# Tests both Graph::Layout::Aesthetic::Force and 
# Graph::Layout::Aesthetic::Force::Perl since we need a programmable force
# to do the tests.

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
    check_warnings();
}

BEGIN { use_ok('Graph::Layout::Aesthetic::Force') };
BEGIN { use_ok('Graph::Layout::Aesthetic::Force::Perl') };

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

my $canaries = 0;
{
    package Canary;

    sub new {
        $canaries++;
        return bless [], shift;
    }

    sub DESTROY {
        $canaries--;
    }
}

my $force;
my $destroys;
my $balanced = 0;
{
    package Graph::Layout::Aesthetic::Force::Test1;
    our @ISA = qw(Graph::Layout::Aesthetic::Force::Perl);

    sub DESTROY {
        $destroys++;
        shift->SUPER::DESTROY(@_);
    }
    sub setup {
        main::is(wantarray, "", "scalar context");
        main::is(@_, 2, "Two args to setup");
        main::is($_[0], $force, "First arg is our object");
        main::isa_ok(shift, __PACKAGE__, "First arg is a perl force");
        main::isa_ok(shift, "Graph::Layout::Aesthetic", "Second arg is the state");
          my $canary = Canary->new;
          $balanced++;
          return $canary;
    }

    sub cleanup {
        $balanced--;
        main::is(wantarray, undef, "void context");
        main::is(@_, 3, "Three args to setup");
        main::isa_ok(shift, __PACKAGE__, "First arg is a perl force");
        main::isa_ok(shift, "Graph::Layout::Aesthetic", 
                     "Second arg is the state");
        main::isa_ok(shift, "Canary", "Third arg is the canary");
        # check if forced void return works
        return 9;
    }

    sub gradient {
        main::is(@_, 4, "Four args to gradient");
        main::isa_ok($_[0], __PACKAGE__, "First arg is a perl force");
        main::isa_ok($_[1], "Graph::Layout::Aesthetic", 
                       "Second arg is the state");
        main::is_deeply($_[2], [[0, 0], [0, 0]], "Initial gradient zero");
        main::isa_ok($_[3], "Canary", "Third arg is the canary");
        bless $_[2][0], "Canary";
        bless $_[2], "Canary";
        $canaries +=2;
        $_[2] = bless [bless([1, 2], "Canary"), [3, 4]], "Canary";
        $canaries +=2;
        # check if forced void return works
        return 8;
    }
}

my $gradient;
{
    package Graph::Layout::Aesthetic::Force::Gradient;
    our @ISA = qw(Graph::Layout::Aesthetic::Force::Perl);

    sub DESTROY {
        $destroys++;
        shift->SUPER::DESTROY(@_);
    }

    sub setup {
        $balanced++;
        # Checks forced scalar return
        return;
    }

    sub cleanup {
        $balanced--;
    }

    sub gradient {
        $_[2] = $gradient;
    }
}

{
    package Graph::Layout::Aesthetic::Force::Morph;
    our @ISA = qw(Graph::Layout::Aesthetic::Force::Perl);

    sub DESTROY {
        $destroys++;
        shift->SUPER::DESTROY(@_);
    }

    sub setup {
        my $canary = Canary->new;
        $balanced++;
        return $canary;
    }

    sub cleanup {
        $balanced--;
        main::is(@_, 3, "Three args");
        main::is(shift, __PACKAGE__, "force was replaced by class");
        main::is(shift, 7, "State was replaced");
        main::is(shift, 9, "Closure was replaced");
    }

    sub gradient {
        $_[0] = ref($_[0]);
        $_[1] = 7;
        $_[2] = $gradient;
        $_[3] = 9;
    }
}

{
    package Graph::Layout::Aesthetic::Force::NoSetup;
    our @ISA = qw(Graph::Layout::Aesthetic::Force::Perl);

    sub DESTROY {
        $destroys++;
        shift->SUPER::DESTROY(@_);
    }

    sub setup {
        die "Bad setup\n";
    }
}

my $bad_count = 124;
{
    package Graph::Layout::Aesthetic::Force::NoCleanup;
    our @ISA = qw(Graph::Layout::Aesthetic::Force::Perl);

    sub DESTROY {
        $destroys++;
        shift->SUPER::DESTROY(@_);
    }

    sub setup {
        my $canary = Canary->new;
        $canaries++;
        return $canary;
    }

    sub gradient {
        return @$gradient;
    }
 
    # Without bad_count the error messages collapse
    sub cleanup {
        $canaries--;
        ++$bad_count;
        die "Bad cleanup $bad_count\n";
    }
}

{
    package Graph::Layout::Aesthetic::Force::EndDie;
    our @ISA = qw(Graph::Layout::Aesthetic::Force::Perl);

    sub DESTROY {
        $destroys++;
        shift->SUPER::DESTROY(@_);
        die "DESTROY die\n";
    }

    sub setup {
        my $canary = Canary->new;
        $balanced++;
        return $canary;
    }

    sub gradient {
        return @$gradient;
    }

    sub cleanup {
        $balanced--;
        die "cleanup die\n";
    }
}

{
    package Graph::Layout::Aesthetic::Force::GradientClear;
    our @ISA = qw(Graph::Layout::Aesthetic::Force::Perl);

    sub DESTROY {
        $destroys++;
        shift->SUPER::DESTROY(@_);
    }

    sub setup {
        my $canary = Canary->new;
        $balanced++;
        return $canary;
    }

    sub gradient {
        # Try to shoot away the force from under us
        $_[1]->clear_forces;
        return @$gradient;
    }

    sub cleanup {
        $balanced--;
    }
}

{
    package Graph::Layout::Aesthetic::Force::NoGradient;
    our @ISA = qw(Graph::Layout::Aesthetic::Force::Perl);

    sub DESTROY {
        $destroys++;
        shift->SUPER::DESTROY(@_);
    }

    sub setup {
        $balanced++;
        return;
    }

    sub cleanup {
        $balanced--;
    }
}

{
    package Graph::Layout::Aesthetic::Force::Exit;
    our @ISA = qw(Graph::Layout::Aesthetic::Force::Perl);

    sub setup {
        return;
    }

    sub gradient {
        return;
    }

    sub cleanup {
        exit 0;
    }
}

my ($when, $pause_count);
{
    package Graph::Layout::Aesthetic::Force::Pause;
    our @ISA = qw(Graph::Layout::Aesthetic::Force::Perl);

    sub DESTROY {
        $destroys++;
        shift->SUPER::DESTROY(@_);
    }

    sub setup {
        $balanced++;
        return;
    }

    sub cleanup {
        $balanced--;
    }

    sub gradient {
        my $aglo = $_[1];
        main::is($aglo->paused, "");
        $aglo->pause if $pause_count == $when;
        $pause_count++;
    }
}

my $aglo_destroys;
{
    my $f = \&Graph::Layout::Aesthetic::DESTROY;
    no warnings 'redefine';
    *Graph::Layout::Aesthetic::DESTROY = sub($ ) {
        $aglo_destroys++;
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

$destroys = 0;
$force = Graph::Layout::Aesthetic::Force::Test1->new;
$force = undef;
is($destroys, 1, "Test force gets destroyed");

# Check DESTROY chain;
$destroys = $force_destroys = 0;
$force = Graph::Layout::Aesthetic::Force::Test1->new;
$force = undef;
is($destroys, 1, "Test force gets destroyed");
is($force_destroys, 1, "Base force got chained");

# By only now loading Graph::Layout::Aesthetic the above stuff
# actually also tested if the XS code still got properly loaded
BEGIN { use_ok('Graph::Layout::Aesthetic') };
BEGIN { use_ok('Graph::Layout::Aesthetic::Topology') };

my $topo2 = Graph::Layout::Aesthetic::Topology->new_vertices(2);
$topo2->add_edge(0, 1);
$topo2->finish;
$aglo_destroys = 0;
my $aglo = Graph::Layout::Aesthetic->new($topo2);
$destroys = 0;
$force = Graph::Layout::Aesthetic::Force::Test1->new;
is($canaries, 0, "No canaries");
$aglo->_add_force($force);
is($canaries, 1, "One canary");
is($destroys, 0, "Force still alive");
is($aglo_destroys, 0, "Aglo is alive");
$aglo = undef;
is($aglo_destroys, 1, "Aglo is gone");
is($destroys, 0, "Force still alive");
is($canaries, 0, "No more canaries");
$force = undef;
is($destroys, 1, "Force Gone");

# Now leave force only on aglo
$aglo_destroys = 0;
$aglo = Graph::Layout::Aesthetic->new($topo2);
$destroys = 0;
$force = Graph::Layout::Aesthetic::Force::Test1->new;
is($canaries, 0, "No canaries");
$aglo->_add_force($force);
is($canaries, 1, "One canary");
$force = undef;
is($destroys, 0, "Force still alive");
is($aglo_destroys, 0, "Aglo is alive");
is($canaries, 1, "One canary");
$aglo = undef;
is($aglo_destroys, 1, "Aglo is gone");
is($destroys, 1, "Force Gone");
is($canaries, 0, "No canaries");

# Add two forces
$aglo_destroys = 0;
$aglo = Graph::Layout::Aesthetic->new($topo2);
$destroys = 0;
$force = Graph::Layout::Aesthetic::Force::Test1->new;
is($canaries, 0, "No canaries");
$aglo->_add_force($force);
is($canaries, 1, "One canary");
$force = Graph::Layout::Aesthetic::Force::Test1->new;
$aglo->_add_force($force);
is($canaries, 2, "Two canaries");
is($destroys, 0, "Force still alive");
is($aglo_destroys, 0, "Aglo is alive");
$aglo = undef;
is($aglo_destroys, 1, "Aglo is gone");
is($destroys, 1, "One force still alive");
is($canaries, 0, "No more canaries");
$force = undef;
is($destroys, 2, "All forces gone");

# Add same force twice
$aglo_destroys = 0;
$aglo = Graph::Layout::Aesthetic->new($topo2);
$destroys = 0;
$force = Graph::Layout::Aesthetic::Force::Test1->new;
is($canaries, 0, "No canaries");
$aglo->_add_force($force);
is($canaries, 1, "One canary");
$aglo->_add_force($force);
is($canaries, 2, "Two canaries");
is($destroys, 0, "Force still alive");
is($aglo_destroys, 0, "Aglo is alive");
$aglo = undef;
is($aglo_destroys, 1, "Aglo is gone");
is($destroys, 0, "Force still alive");
is($canaries, 0, "No more canaries");
$force = undef;
is($destroys, 1, "Force gone");

# Same, but now drop $force first
$aglo_destroys = 0;
$aglo = Graph::Layout::Aesthetic->new($topo2);
$destroys = 0;
$force = Graph::Layout::Aesthetic::Force::Test1->new;
is($canaries, 0, "No canaries");
$aglo->_add_force($force);
is($canaries, 1, "One canary");
$aglo->_add_force($force);
is($canaries, 2, "Two canaries");
$force = undef;
is($canaries, 2, "Two canaries");
is($destroys, 0, "Force still alive");
is($aglo_destroys, 0, "Aglo is alive");
$aglo = undef;
is($aglo_destroys, 1, "Aglo is gone");
is($destroys, 1, "Force is gone");
is($canaries, 0, "No more canaries");

# Now drop using clear_forces
$aglo_destroys = 0;
$aglo = Graph::Layout::Aesthetic->new($topo2);
$destroys = 0;
$force = Graph::Layout::Aesthetic::Force::Test1->new;
is($canaries, 0, "No canaries");
$aglo->_add_force($force);
is($canaries, 1, "One canary");
$aglo->_add_force($force);
is($canaries, 2, "Two canaries");
$force = undef;
is($canaries, 2, "Two canaries");
is($destroys, 0, "Force still alive");
$aglo->clear_forces;
is($aglo_destroys, 0, "Aglo is alive");
is($destroys, 1, "Force is gone");
is($canaries, 0, "No more canaries");
$aglo = undef;
is($aglo_destroys, 1, "Aglo is gone");

# Now actually apply the force
$aglo_destroys = 0;
$aglo = Graph::Layout::Aesthetic->new($topo2);
$destroys = 0;
$force = Graph::Layout::Aesthetic::Force::Test1->new;
is($canaries, 0, "No canaries");
$aglo->_add_force($force);
is($canaries, 1, "One canary");
$force = undef;
is($canaries, 1, "One canary");
is($destroys, 0, "Force still alive");
$aglo->zero;
$aglo->step(100, 0);
is_deeply(scalar $aglo->all_coordinates, [[1, 2], [3, 4]], 
          "Gradient gets applied properly");
is($canaries, 1, "One canary");
is($destroys, 0, "Force still alive");
is($aglo_destroys, 0, "Aglo is still alive");
$aglo = undef;
is($aglo_destroys, 1, "Aglo is gone");
is($destroys, 1, "Force is gone");
is($canaries, 0, "No more canaries");

# Check name
is(Graph::Layout::Aesthetic::Force::Test1->name, "Test1", "Default name works as class method");
$force = Graph::Layout::Aesthetic::Force::Test1->new;
is($force->name, "Test1", "Default name works for the basic case");

@Foo::Bar::ISA = qw(Graph::Layout::Aesthetic::Force::Test1);
is(Foo::Bar->name, "Bar", "Default name works as class method");
$force = Foo::Bar->new;
is($force->name, "Bar", "Default name works for non-force derived case");

@Graph::Layout::Aesthetic::Force::Test1::Foo::ISA = qw(Graph::Layout::Aesthetic::Force::Test1);
is(Graph::Layout::Aesthetic::Force::Test1::Foo->name, "Test1::Foo", "Default name works relative to Graph::Layout::Aesthetic::Force");
$force = Graph::Layout::Aesthetic::Force::Test1::Foo->new;
is($force->name, "Test1::Foo", "Default name works relative to Graph::Layout::Aesthetic::Force");
$force = undef;

# Checking failure modes of gradient
$aglo_destroys = 0;
$aglo = Graph::Layout::Aesthetic->new($topo2, 3);
$destroys = 0;
$force = Graph::Layout::Aesthetic::Force::Gradient->new;
$aglo->_add_force($force);
$force = undef;
is($destroys, 0, "Force still alive");
$aglo->zero;
$gradient = [[1, 2, 5], [3, 4, 6]];
$aglo->step(100, 0);
is_deeply(scalar $aglo->all_coordinates, [[1, 2, 5], [3, 4, 6]], 
          "Gradient gets applied properly");
KillRef->test($gradient->[0]);
KillRef->test($gradient);
$gradient = 5;
eval { $aglo->step(100, 0) };
like($@, qr!^Gradient is not a reference anymore at !, 
     "Must assign reference");
$gradient = {};
eval { $aglo->step(100, 0) };
like($@, qr!^Gradient is not an array reference anymore at !,
     "Must assign an array reference");
$gradient = [];
eval { $aglo->step(100, 0) };
like($@, 
     qr!Expected force->gradient to return a size 2 list, but got 0 values at!,
     "Must return #vertices list");
$gradient = [1, 2];
eval { $aglo->step(100, 0) };
like($@, qr!Gradient for vertex 1 is not a reference at !, 
     "All elements must be references");
my @hole2;
$#hole2 = 1;
$gradient = \@hole2;
eval { $aglo->step(100, 0) };
like($@, qr!^Gradient for vertex 1 is unset at !, "All elements must be set");
$gradient = [1, {}];
eval { $aglo->step(100, 0) };
like($@, qr!Gradient for vertex 1 is not an array reference at !,
     "All elements must be array references");
$gradient = [1, []];
eval { $aglo->step(100, 0) };
like($@, qr!Gradient for vertex 1 is a reference to an array of size 0, expected 3 at!, "coordinate arrays of size dimension");
my @hole3 = 1..3;
delete $hole3[0];
$gradient = [1, \@hole3];
eval { $aglo->step(100, 0) };
like($@, qr!Gradient for vertex 1, coordinate 0 is unset at !,
     "All elements must be filled in");
is($destroys, 0, "Force still alive");
is($aglo_destroys, 0, "Aglo is still alive");
$aglo = undef;
is($aglo_destroys, 1, "Aglo is gone");
is($destroys, 1, "Force gone");

# Check modifying gradient arguments
$aglo_destroys = 0;
$aglo = Graph::Layout::Aesthetic->new($topo2);
$destroys = 0;
$force = Graph::Layout::Aesthetic::Force::Morph->new;
$aglo->_add_force($force);
$force = undef;
$aglo->zero;
$gradient = [[1, 2], [3, 4]];
is($destroys, 0, "Force still alive");
$aglo->step(100, 0);
is($destroys, 0, 
   "Force is still there (needed to hold the adress of ae_cleanup_perl)");
is($aglo_destroys, 0, "Aglo is still alive");
$aglo = undef;
is($aglo_destroys, 1, "Aglo is gone");
is($destroys, 1, "Force gone");

# Failure modes of call
# - No setup
$aglo_destroys = 0;
$aglo = Graph::Layout::Aesthetic->new($topo2);
$destroys = 0;
$force = Graph::Layout::Aesthetic::Force::NoSetup->new;
eval { $aglo->_add_force($force) };
is($@, "Bad setup\n", "Proper eval drop for setup");
is($destroys, 0, "Force still alive");
$force = undef;
is($destroys, 1, "Force gone");
is($aglo_destroys, 0, "Aglo is still alive");
$aglo = undef;
is($aglo_destroys, 1, "Aglo is gone");
is($destroys, 1, "Force gone");

# - No cleanup
$aglo_destroys = 0;
$aglo = Graph::Layout::Aesthetic->new($topo2);
$destroys = 0;
$force = Graph::Layout::Aesthetic::Force::NoCleanup->new;
$aglo->_add_force($force, 0);
$aglo->_add_force($force, 1);
$aglo->_add_force($force, 2);
$aglo->_add_force($force, 3);
$force = undef;
is($destroys, 0, "Force still alive");
is($aglo_destroys, 0, "Aglo is still alive");
$bad_count = -1;
eval { $aglo->clear_forces };
is($@, "Bad cleanup 0\n", "clear_forces passes on exceptions");
my $forces = $aglo->forces;
is(@$forces, 3, "Three forces left (first one of four died");
isa_ok($forces->[0][0], "Graph::Layout::Aesthetic::Force::NoCleanup", "It's the force we added");
is($forces->[0][1], 2, "Forces were added in reverse order");
is($forces->[1][0], $forces->[0][0], "Added forces are the same");
is($forces->[1][1], 1, "Forces were added in reverse order");
is($forces->[2][0], $forces->[0][0], "Added forces are the same");
is($forces->[2][1], 0, "Forces were added in reverse order");
KillRef->test($forces->[0]);
KillRef->test($forces);
check_warnings;
is($aglo_destroys, 0, "Aglo is still alive");
$@="z1\n";
$aglo = undef;
is($@, "z1
\t(in cleanup) Bad cleanup 1
\t(in cleanup) Bad cleanup 2
\t(in cleanup) Bad cleanup 3\n", 'Errors accumulate in $@');
is(@warnings, 3, "Cleanup warning");
is($warnings[$_-1], "\t(in cleanup) Bad cleanup $_\n", 
   "implied cleanup done") for 1..3;
@warnings = ();
is($aglo_destroys, 1, "Aglo is gone");
is($destroys, 1, "Force gone");
is($canaries, 0, "No more canaries");

# Die in cleanup and DESTROY
$aglo_destroys = 0;
$aglo = Graph::Layout::Aesthetic->new($topo2);
$destroys = 0;
$force = Graph::Layout::Aesthetic::Force::EndDie->new;
$aglo->_add_force($force);
$force = undef;
is($destroys, 0, "Force still alive");
check_warnings;
is($aglo_destroys, 0, "Aglo is still alive");
$@="z2\n";
$aglo = undef;
is($@, "z2
\t(in cleanup) cleanup die
\t(in cleanup) DESTROY die\n", "Errors accumulate");
is(@warnings, 2, "Both dies are now a warning");
is($warnings[0], "\t(in cleanup) cleanup die\n", 
   "Also test \$\@ containing \\0");
is($warnings[1], "\t(in cleanup) DESTROY die\n");
@warnings = ();
is($aglo_destroys, 1, "Aglo is gone");
is($destroys, 1, "Force gone");
is($canaries, 0, "No more canaries");

# - No gradient
$aglo_destroys = 0;
$aglo = Graph::Layout::Aesthetic->new($topo2);
$destroys = 0;
$force = Graph::Layout::Aesthetic::Force::NoGradient->new;
$aglo->_add_force($force);
$force = undef;
is($destroys, 0, "Force still alive");
$aglo->zero;
eval { $aglo->step(100, 0) };
like($@, qr!^Can.t locate object method "gradient" via package "Graph::Layout::Aesthetic::Force::NoGradient" at !, "gradient failure gets passed on");
is($destroys, 0, "Force still alive");
is($aglo_destroys, 0, "Aglo is still alive");
$aglo = undef;
is($aglo_destroys, 1, "Aglo is gone");
is($destroys, 1, "Force gone");

# Force suicide
$aglo_destroys = 0;
$aglo = Graph::Layout::Aesthetic->new($topo2);
$destroys = 0;
$force = Graph::Layout::Aesthetic::Force::GradientClear->new;
$aglo->_add_force($force);
$aglo->_add_force($force);
# Don't destroy $force here. There seems to be more chance of problems if
# it's kept around
is($destroys, 0, "Force still alive");
$aglo->zero;
check_warnings;
$aglo->step(100, 0);
is(@warnings, 1);
like($warnings[0], qr!^Forces were cleared during an actual forcing calculation at !, "Proper warning if you clear forces during a gradient call");
@warnings = ();
is($destroys, 0, "Force still alive");
$force = undef;
is($destroys, 1, "Force is gone");
is($aglo_destroys, 0, "Aglo is still alive");
$aglo = undef;
is($aglo_destroys, 1, "Aglo is gone");
is($destroys, 1, "Force gone");

# check register/name2force
$force = Graph::Layout::Aesthetic::Force::Test1->new;
$force->register;
eval { $force->register };
like($@, qr!A force named Test1 already exists at !, "Cannot register twice");
$force->register("baz");
is(Graph::Layout::Aesthetic::Force::name2force("Test1"), $force, 
                                               "Can lookup by default name");
is(Graph::Layout::Aesthetic::Force::name2force("baz"), $force, 
                                               "Can lookup by given name");
eval { Graph::Layout::Aesthetic::Force::name2force("bat") };
like($@, qr!Can.t locate Graph/Layout/Aesthetic/Force/bat.pm in \@INC \(\@INC contains: !, "Fails to load non-existing force");
ok(!$INC{"Graph/Layout/Aesthetic/Force/NodeRepulsion.pm"},
   "Node repulsion not yet loaded");
$force = Graph::Layout::Aesthetic::Force::name2force("NodeRepulsion");
isa_ok($force, "Graph::Layout::Aesthetic::Force::NodeRepulsion", 
       "Can demand lod forces");
ok($INC{"Graph/Layout/Aesthetic/Force/NodeRepulsion.pm"},
   "Node repulsion loaded");

# check user_data
for my $data (qw(user_data _private_data)) {
    my $force = Graph::Layout::Aesthetic::Force::NodeRepulsion->new;
    is($force->$data, undef);
    is($force->$data(5), undef);
    is($force->$data(6), 5);
    is($force->$data, 6);
    is($force->$data, 6);
    $force->$data(7);
    is($force->$data, 7);
    is($force->$data(Canary->new), 7);
    is($canaries, 1);
    isa_ok($force->$data(8), "Canary");
    is($canaries, 0);
    $force->$data(Canary->new);
    is($canaries, 1);
    $force = undef;
    is($canaries, 0);
}

# The delayed "pause" tests from Aesthetic
$aglo = Graph::Layout::Aesthetic->new($topo2);
$force = Graph::Layout::Aesthetic::Force::Pause->new;
$aglo->_add_force($force);
for my $start_pause (0, 1) {
    for $_ (0..3) {
        $when = $_;
        $pause_count = 0;
        $aglo->paused($start_pause);
        $aglo->init_gloss(1000, 1, 3);
        $aglo->_gloss;
        if ($_ == 3) {
            is($pause_count, 3, "Done only start event");
            is($aglo->iterations, 0, "No iterations done");
            is($aglo->paused, "");
        } else {
            is($pause_count, $_+1, "Done only start event");
            is($aglo->iterations, 2-$_, "No iterations done");
            is($aglo->paused, 1);
        }
    }
}
$force = undef;
$aglo = undef;

# Final tests
is($balanced, 0, "Every setup has a cleanup and vice versa");

# As a last thing we try to exit through $aglo and implied $force DESTROY
# - No gradient
$aglo = Graph::Layout::Aesthetic->new($topo2);
$force = Graph::Layout::Aesthetic::Force::Exit->new;
$aglo->_add_force($force);
$force = undef;
$aglo = undef;
diag("Survived exit ???");
fail("Survived exit. We should not get here");
