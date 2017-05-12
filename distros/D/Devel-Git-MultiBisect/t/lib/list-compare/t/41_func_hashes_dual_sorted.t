# perl
#$Id$
# 41_func_hashes_dual_sorted.t
use strict;
use Test::More tests =>  46;
use List::Compare::Functional qw(:originals :aliases);
use lib ("./t");
use Test::ListCompareSpecial qw( :seen :func_wrap :hashes :results );
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
@union = get_union( [ \%h0, \%h1 ] );
is_deeply( \@union, \@pred, "Got expected union");

$union_ref = get_union_ref( [ \%h0, \%h1 ] );
is_deeply( $union_ref, \@pred, "Got expected union");

@pred = qw( baker camera delta edward fargo golfer );
@shared = get_shared( [ \%h0, \%h1 ] );
is_deeply( \@shared, \@pred, "Got expected shared");

$shared_ref = get_shared_ref( [ \%h0, \%h1 ] );
is_deeply( $shared_ref, \@pred, "Got expected shared");

@pred = qw( baker camera delta edward fargo golfer );
@intersection = get_intersection( [ \%h0, \%h1 ] );
is_deeply(\@intersection, \@pred, "Got expected intersection");

$intersection_ref = get_intersection_ref( [ \%h0, \%h1 ] );
is_deeply($intersection_ref, \@pred, "Got expected intersection");

@pred = qw( abel );
@unique = get_unique( [ \%h0, \%h1 ] );
is_deeply(\@unique, \@pred, "Got expected unique");

$unique_ref = get_unique_ref( [ \%h0, \%h1 ] );
is_deeply($unique_ref, \@pred, "Got expected unique");

@pred = (
    [ 'abel' ],
    [ 'hilton' ],
);
$unique_all_ref = get_unique_all( [ \%h0, \%h1 ] );
is_deeply($unique_all_ref, [ @pred ],
    "Got expected values for get_unique_all()");

@pred = qw ( hilton );
@complement = get_complement( [ \%h0, \%h1 ] );
is_deeply(\@complement, \@pred, "Got expected complement");

$complement_ref = get_complement_ref( [ \%h0, \%h1 ] );
is_deeply($complement_ref, \@pred, "Got expected complement");

@pred = (
    [ qw( hilton ) ],
    [ qw( abel ) ],
);
$complement_all_ref = get_complement_all( [ \%h0, \%h1 ] );
is_deeply($complement_all_ref, [ @pred ],
    "Got expected values for get_complement_all()");

@pred = qw( abel hilton );
@symmetric_difference = get_symmetric_difference( [ \%h0, \%h1 ] );
is_deeply(\@symmetric_difference, \@pred, "Got expected symmetric_difference");

$symmetric_difference_ref = get_symmetric_difference_ref( [ \%h0, \%h1 ] );
is_deeply($symmetric_difference_ref, \@pred, "Got expected symmetric_difference");

@symmetric_difference = get_symdiff( [ \%h0, \%h1 ] );
is_deeply(\@symmetric_difference, \@pred, "Got expected symmetric_difference");

$symmetric_difference_ref = get_symdiff_ref( [ \%h0, \%h1 ] );
is_deeply($symmetric_difference_ref, \@pred, "Got expected symmetric_difference");

@pred = qw( abel hilton );
@nonintersection = get_nonintersection( [ \%h0, \%h1 ] );
is_deeply(\@nonintersection, \@pred, "Got expected nonintersection");

$nonintersection_ref = get_nonintersection_ref( [ \%h0, \%h1 ] );
is_deeply($nonintersection_ref, \@pred, "Got expected nonintersection");

@pred = qw( abel abel baker baker camera camera delta delta delta edward
edward fargo fargo golfer golfer hilton );
@bag = get_bag( [ \%h0, \%h1 ] );
is_deeply(\@bag, \@pred, "Got expected bag");

$bag_ref = get_bag_ref( [ \%h0, \%h1 ] );
is_deeply($bag_ref, \@pred, "Got expected bag");

$LR = is_LsubsetR( [ \%h0, \%h1 ] );
ok(! $LR, "Got expected subset relationship");

$RL = is_RsubsetL( [ \%h0, \%h1 ] );
ok(! $RL, "Got expected subset relationship");

$eqv = is_LequivalentR( [ \%h0, \%h1 ] );
ok(! $eqv, "Got expected equivalent relationship");

$eqv = is_LeqvlntR( [ \%h0, \%h1 ] );
ok(! $eqv, "Got expected equivalent relationship");

$disj = is_LdisjointR( [ \%h0, \%h1 ] );
ok(! $disj, "Got expected disjoint relationship");

{
    my ($rv, $stdout, $stderr);
    capture(
        sub { $rv = print_subset_chart( [ \%h0, \%h1 ] ); },
        \$stdout,
    );
    ok($rv, "print_subset_chart() returned true value");
    like($stdout, qr/Subset Relationships/,
        "Got expected chart header");
}
{
    my ($rv, $stdout, $stderr);
    capture(
        sub { $rv = print_equivalence_chart( [ \%h0, \%h1 ] ); },
        \$stdout,
    );
    ok($rv, "print_equivalence_chart() returned true value");
    like($stdout, qr/Equivalence Relationships/,
        "Got expected chart header");
}
     
@args = qw( abel baker camera delta edward fargo golfer hilton icon jerky zebra );
is_deeply(func_all_is_member_which( [ \%h0, \%h1 ], \@args ),
    $test_member_which_dual,
    "is_member_which() returned all expected values");

is_deeply(func_all_is_member_which_ref( [ \%h0, \%h1 ], \@args ),
    $test_member_which_dual,
    "is_member_which() returned all expected values");

$memb_hash_ref = are_members_which( [ \%h0, \%h1 ] , \@args );
ok(func_wrap_are_members_which(
    $memb_hash_ref,
    $test_members_which,
), "are_members_which() returned all expected values");

is_deeply(func_all_is_member_any( [ \%h0, \%h1 ], \@args ),
    $test_member_any_dual,
    "is_member_any() returned all expected values");

$memb_hash_ref = are_members_any( [ \%h0, \%h1 ], \@args );
ok(func_wrap_are_members_any(
    $memb_hash_ref,
    $test_members_any,
), "are_members_any() returned all expected values");

$vers = get_version;
ok($vers, "get_version() returned true value");

$LR = is_LsubsetR( [ \%h2, \%h3 ] );
ok(! $LR, "non-subset correctly determined");

$RL = is_RsubsetL( [ \%h2, \%h3 ] );
ok($RL, "subset correctly determined");

$eqv = is_LequivalentR( [ \%h2, \%h3 ] );
ok(! $eqv, "non-equivalence correctly determined");

$eqv = is_LeqvlntR( [ \%h2, \%h3 ] );
ok(! $eqv, "non-equivalence correctly determined");

$disj = is_LdisjointR( [ \%h2, \%h3 ] );
ok(! $disj, "non-disjoint correctly determined");

$eqv = is_LequivalentR( [ \%h3, \%h4 ] );
ok($eqv, "equivalence correctly determined");

$eqv = is_LeqvlntR( [ \%h3, \%h4 ] );
ok($eqv, "equivalence correctly determined");

$disj = is_LdisjointR( [ \%h3, \%h4 ] );
ok(! $disj, "non-disjoint correctly determined");

ok(0 == get_intersection( [ \%h4, \%h8 ] ), "no intersection, as expected");
ok(0 == scalar(@{get_intersection_ref( [ \%h4, \%h8 ] )}),
    "no intersection, as expected");
$disj = is_LdisjointR( [ \%h4, \%h8 ] );
ok($disj, "disjoint correctly determined");
