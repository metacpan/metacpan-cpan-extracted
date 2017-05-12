# perl
#$Id$
# 37_func_lists_alt_dual_sorted.t
use strict;
use Test::More tests =>  50;
use List::Compare::Functional qw(:originals :aliases);
use lib ("./t");
use Test::ListCompareSpecial qw( :seen :func_wrap :arrays :results );
use IO::CaptureOutput qw( capture );

my @pred = ();
my %seen = ();
my %pred = ();
my @unpred = ();
my (@unique, @complement, @intersection, @union, @symmetric_difference, @bag);
my ($unique_ref, $complement_ref, $intersection_ref, $union_ref,
$symmetric_difference_ref, $bag_ref);
my ($LR, $RL, $eqv, $disj, $return, $vers);
my (@nonintersection, @shared);
my ($nonintersection_ref, $shared_ref);
my ($memb_hash_ref, $memb_arr_ref, @memb_arr);
my ($unique_all_ref, $complement_all_ref);
my @args;

@pred = qw(abel baker camera delta edward fargo golfer hilton);
@union = get_union( { lists => [ \@a0, \@a1 ] } );
is_deeply( \@union, \@pred, "Got expected union");

$union_ref = get_union_ref( { lists => [ \@a0, \@a1 ] } );
is_deeply( $union_ref, \@pred, "Got expected union");

@pred = qw( baker camera delta edward fargo golfer );
@shared = get_shared( { lists => [ \@a0, \@a1 ] } );
is_deeply( \@shared, \@pred, "Got expected shared");

$shared_ref = get_shared_ref( { lists => [ \@a0, \@a1 ] } );
is_deeply( $shared_ref, \@pred, "Got expected shared");

@pred = qw( baker camera delta edward fargo golfer );
@intersection = get_intersection( { lists => [ \@a0, \@a1 ] } );
is_deeply(\@intersection, \@pred, "Got expected intersection");

$intersection_ref = get_intersection_ref( { lists => [ \@a0, \@a1 ] } );
is_deeply($intersection_ref, \@pred, "Got expected intersection");

@pred = qw( abel );
@unique = get_unique( { lists => [ \@a0, \@a1 ] } );
is_deeply(\@unique, \@pred, "Got expected unique");

$unique_ref = get_unique_ref( { lists => [ \@a0, \@a1 ] } );
is_deeply($unique_ref, \@pred, "Got expected unique");

@pred = (
    [ 'abel' ],
    [ 'hilton' ],
);
$unique_all_ref = get_unique_all( { lists => [ \@a0, \@a1 ] } );
is_deeply($unique_all_ref, [ @pred ],
    "Got expected values for get_unique_all()");

@pred = qw ( hilton );
@complement = get_complement( { lists => [ \@a0, \@a1 ] } );
is_deeply(\@complement, \@pred, "Got expected complement");

$complement_ref = get_complement_ref( { lists => [ \@a0, \@a1 ] } );
is_deeply($complement_ref, \@pred, "Got expected complement");

@pred = (
    [ qw( hilton ) ],
    [ qw( abel ) ],
);
$complement_all_ref = get_complement_all( { lists => [ \@a0, \@a1 ] } );
is_deeply($complement_all_ref, [ @pred ],
    "Got expected values for get_complement_all()");

@pred = qw( abel hilton );
@symmetric_difference = get_symmetric_difference( { lists => [ \@a0, \@a1 ] } );
is_deeply(\@symmetric_difference, \@pred, "Got expected symmetric_difference");

$symmetric_difference_ref = get_symmetric_difference_ref( { lists => [ \@a0, \@a1 ] } );
is_deeply($symmetric_difference_ref, \@pred, "Got expected symmetric_difference");

@symmetric_difference = get_symdiff( { lists => [ \@a0, \@a1 ] } );
is_deeply(\@symmetric_difference, \@pred, "Got expected symmetric_difference");

$symmetric_difference_ref = get_symdiff_ref( { lists => [ \@a0, \@a1 ] } );
is_deeply($symmetric_difference_ref, \@pred, "Got expected symmetric_difference");

@pred = qw( abel hilton );
@nonintersection = get_nonintersection( { lists => [ \@a0, \@a1 ] } );
is_deeply(\@nonintersection, \@pred, "Got expected nonintersection");

$nonintersection_ref = get_nonintersection_ref( { lists => [ \@a0, \@a1 ] } );
is_deeply($nonintersection_ref, \@pred, "Got expected nonintersection");

@pred = qw( abel abel baker baker camera camera delta delta delta edward
edward fargo fargo golfer golfer hilton );
@bag = get_bag( { lists => [ \@a0, \@a1 ] } );
is_deeply(\@bag, \@pred, "Got expected bag");

$bag_ref = get_bag_ref( { lists => [ \@a0, \@a1 ] } );
is_deeply($bag_ref, \@pred, "Got expected bag");

$LR = is_LsubsetR( { lists => [ \@a0, \@a1 ] } );
ok(! $LR, "Got expected subset relationship");

$RL = is_RsubsetL( { lists => [ \@a0, \@a1 ] } );
ok(! $RL, "Got expected subset relationship");

$eqv = is_LequivalentR( { lists => [ \@a0, \@a1 ] } );
ok(! $eqv, "Got expected equivalent relationship");

$eqv = is_LeqvlntR( { lists => [ \@a0, \@a1 ] } );
ok(! $eqv, "Got expected equivalent relationship");

$disj = is_LdisjointR( { lists => [ \@a0, \@a1 ] } );
ok(! $disj, "Got expected disjoint relationship");

{
    my ($rv, $stdout, $stderr);
    capture(
        sub { $rv = print_subset_chart( { lists => [ \@a0, \@a1 ] } ); },
        \$stdout,
    );
    ok($rv, "print_subset_chart() returned true value");
    like($stdout, qr/Subset Relationships/,
        "Got expected chart header");
}

my $scalar = q{string};
eval { my $rv = print_subset_chart( { lists => \$scalar } ); };
like($@, qr/^Need to define 'lists' key properly/,
    "Got expected error message re value for 'lists' key other than array ref");

eval { my $rv = print_subset_chart( { key => 'value' } ); };
like($@, qr/^Need to define 'lists' key properly/,
    "Got expected error message re value for 'lists' key other than array ref");

{
    my ($rv, $stdout, $stderr);
    capture(
        sub { $rv = print_equivalence_chart( { lists => [ \@a0, \@a1 ] } ); },
        \$stdout,
    );
    ok($rv, "print_equivalence_chart() returned true value");
    like($stdout, qr/Equivalence Relationships/,
        "Got expected chart header");
}
     
eval { my $rv = print_equivalence_chart( { lists => \$scalar } ); };
like($@, qr/^Need to define 'lists' key properly/,
    "Got expected error message re value for 'lists' key other than array ref");

eval { my $rv = print_equivalence_chart( { key => 'value' } ); };
like($@, qr/^Need to define 'lists' key properly/,
    "Got expected error message re value for 'lists' key other than array ref");

@args = qw( abel baker camera delta edward fargo golfer hilton icon jerky zebra );
is_deeply(func_all_is_member_which_alt( [ \@a0, \@a1 ], \@args ),
    $test_member_which_dual,
    "is_member_which() returned all expected values");

is_deeply(func_all_is_member_which_ref_alt( [ \@a0, \@a1 ], \@args ),
    $test_member_which_dual,
    "is_member_which() returned all expected values");

$memb_hash_ref = are_members_which( {
    lists => [ \@a0, \@a1 ],
    items => \@args,
} );
ok(func_wrap_are_members_which(
    $memb_hash_ref,
    $test_members_which,
), "are_members_which() returned all expected values");

is_deeply(func_all_is_member_any( [ \@a0, \@a1 ], \@args ),
    $test_member_any_dual,
    "is_member_any() returned all expected values");

$memb_hash_ref = are_members_any( {
    lists => [ \@a0, \@a1 ],
    items => \@args,
} );
ok(func_wrap_are_members_any(
    $memb_hash_ref,
    $test_members_any,
), "are_members_any() returned all expected values");

$vers = get_version;
ok($vers, "get_version() returned true value");

$LR = is_LsubsetR( { lists => [ \@a2, \@a3 ] } );
ok(! $LR, "non-subset correctly determined");

$RL = is_RsubsetL( { lists => [ \@a2, \@a3 ] } );
ok($RL, "subset correctly determined");

$eqv = is_LequivalentR( { lists => [ \@a2, \@a3 ] } );
ok(! $eqv, "non-equivalence correctly determined");

$eqv = is_LeqvlntR( { lists => [ \@a2, \@a3 ] } );
ok(! $eqv, "non-equivalence correctly determined");

$disj = is_LdisjointR( { lists => [ \@a2, \@a3 ] } );
ok(! $disj, "non-disjoint correctly determined");

$eqv = is_LequivalentR( { lists => [ \@a3, \@a4 ] } );
ok($eqv, "equivalence correctly determined");

$eqv = is_LeqvlntR( { lists => [ \@a3, \@a4 ] } );
ok($eqv, "equivalence correctly determined");

$disj = is_LdisjointR( { lists => [ \@a3, \@a4 ] } );
ok(! $disj, "non-disjoint correctly determined");

ok(0 == get_intersection( { lists => [ \@a4, \@a8 ] } ),
    "no intersection, as expected");
ok(0 == scalar(@{get_intersection_ref( { lists => [ \@a4, \@a8 ] } )}),
    "no intersection, as expected");
$disj = is_LdisjointR( { lists => [ \@a4, \@a8 ] } );
ok($disj, "disjoint correctly determined");
