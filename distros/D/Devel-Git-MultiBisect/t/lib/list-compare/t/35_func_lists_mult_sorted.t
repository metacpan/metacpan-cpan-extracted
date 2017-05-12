# perl
#$Id$
# 35_func_lists_mult_sorted.t
use strict;
use Test::More tests =>  51;
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

@pred = qw(abel baker camera delta edward fargo golfer hilton icon jerky);
@union = get_union( [ \@a0, \@a1, \@a2, \@a3, \@a4 ] );
is_deeply( \@union, \@pred, "Got expected union");

$union_ref = get_union_ref( [ \@a0, \@a1, \@a2, \@a3, \@a4 ] );
is_deeply( $union_ref, \@pred, "Got expected union");

@pred = qw(baker camera delta edward fargo golfer hilton icon);
@shared = get_shared( [ \@a0, \@a1, \@a2, \@a3, \@a4 ] );
is_deeply( \@shared, \@pred, "Got expected shared");

$shared_ref = get_shared_ref( [ \@a0, \@a1, \@a2, \@a3, \@a4 ] );
is_deeply( $shared_ref, \@pred, "Got expected shared");

@pred = qw(fargo golfer);
@intersection = get_intersection( [ \@a0, \@a1, \@a2, \@a3, \@a4 ] );
is_deeply(\@intersection, \@pred, "Got expected intersection");

$intersection_ref = get_intersection_ref( [ \@a0, \@a1, \@a2, \@a3, \@a4 ] );
is_deeply($intersection_ref, \@pred, "Got expected intersection");

@pred = qw( jerky );
@unique = get_unique( [ \@a0, \@a1, \@a2, \@a3, \@a4 ], [ 2 ] );
is_deeply(\@unique, \@pred, "Got expected unique");

$unique_ref = get_unique_ref( [ \@a0, \@a1, \@a2, \@a3, \@a4 ], [ 2 ] );
is_deeply($unique_ref, \@pred, "Got expected unique");

eval { $unique_ref = get_unique_ref(
    [ \@a0, \@a1, \@a2, \@a3, \@a4 ],
    [ 2 ],
    [ 'foobar' ]
); };
like($@, qr/Subroutine call requires 1 or 2 references as arguments/,
    "Got expected message for too many arguments");

@pred = qw( abel );
@unique = get_unique( [ \@a0, \@a1, \@a2, \@a3, \@a4 ] );
is_deeply(\@unique, \@pred, "Got expected unique");

$unique_ref = get_unique_ref( [ \@a0, \@a1, \@a2, \@a3, \@a4 ] );
is_deeply($unique_ref, \@pred, "Got expected unique");

@pred = (
    [ 'abel' ],
    [  ],
    [ 'jerky' ],
    [ ],
    [  ],
);
$unique_all_ref = get_unique_all( [ \@a0, \@a1, \@a2, \@a3, \@a4 ] );
is_deeply($unique_all_ref, [ @pred ],
    "Got expected values for get_unique_all()");

@pred = qw( abel icon jerky );
@complement = get_complement([ \@a0, \@a1, \@a2, \@a3, \@a4 ], [ 1 ] );
is_deeply(\@complement, \@pred, "Got expected complement");

$complement_ref = get_complement_ref([ \@a0, \@a1, \@a2, \@a3, \@a4 ], [ 1 ] );
is_deeply($complement_ref, \@pred, "Got expected complement");

@pred = qw ( hilton icon jerky );
@complement = get_complement( [ \@a0, \@a1, \@a2, \@a3, \@a4 ] );
is_deeply(\@complement, \@pred, "Got expected complement");

$complement_ref = get_complement_ref( [ \@a0, \@a1, \@a2, \@a3, \@a4 ] );
is_deeply($complement_ref, \@pred, "Got expected complement");

eval { $complement_ref = get_complement_ref(
    [ \@a0, \@a1, \@a2, \@a3, \@a4 ],
    [ 2 ],
    [ 'foobar' ]
); };
like($@, qr/Subroutine call requires 1 or 2 references as arguments/,
    "Got expected message for too many arguments");

@pred = (
    [ qw( hilton icon jerky ) ],
    [ qw( abel icon jerky ) ],
    [ qw( abel baker camera delta edward ) ],
    [ qw( abel baker camera delta edward jerky ) ],
    [ qw( abel baker camera delta edward jerky ) ],
);
$complement_all_ref = get_complement_all( [ \@a0, \@a1, \@a2, \@a3, \@a4 ] );
is_deeply($complement_all_ref, [ @pred ],
    "Got expected values for get_complement_all()");

@pred = qw( abel jerky );
@symmetric_difference =
    get_symmetric_difference( [ \@a0, \@a1, \@a2, \@a3, \@a4 ] );
is_deeply(\@symmetric_difference, \@pred, "Got expected symmetric_difference");

$symmetric_difference_ref =
    get_symmetric_difference_ref( [ \@a0, \@a1, \@a2, \@a3, \@a4 ] );
is_deeply($symmetric_difference_ref, \@pred, "Got expected symmetric_difference");

@symmetric_difference = get_symdiff( [ \@a0, \@a1, \@a2, \@a3, \@a4 ] );
is_deeply(\@symmetric_difference, \@pred, "Got expected symmetric_difference");

$symmetric_difference_ref = get_symdiff_ref( [ \@a0, \@a1, \@a2, \@a3, \@a4 ] );
is_deeply($symmetric_difference_ref, \@pred, "Got expected symmetric_difference");

@pred = qw( abel baker camera delta edward hilton icon jerky );
@nonintersection = get_nonintersection( [ \@a0, \@a1, \@a2, \@a3, \@a4 ] );
is_deeply( \@nonintersection, \@pred, "Got expected nonintersection");

$nonintersection_ref = get_nonintersection_ref( [ \@a0, \@a1, \@a2, \@a3, \@a4 ] );
is_deeply($nonintersection_ref, \@pred, "Got expected nonintersection");

@pred = qw( abel abel baker baker camera camera delta delta delta edward
edward fargo fargo fargo fargo fargo fargo golfer golfer golfer golfer golfer
hilton hilton hilton hilton icon icon icon icon icon jerky );
@bag = get_bag( [ \@a0, \@a1, \@a2, \@a3, \@a4 ] );
is_deeply(\@bag, \@pred, "Got expected bag");

$bag_ref = get_bag_ref( [ \@a0, \@a1, \@a2, \@a3, \@a4 ] );
is_deeply($bag_ref, \@pred, "Got expected bag");

$LR = is_LsubsetR( [ \@a0, \@a1, \@a2, \@a3, \@a4 ], [ 3,2 ] );
ok($LR, "Got expected subset relationship");

$LR = is_LsubsetR( [ \@a0, \@a1, \@a2, \@a3, \@a4 ], [ 2,3 ] );
ok(! $LR, "Got expected subset relationship");

$LR = is_LsubsetR( [ \@a0, \@a1, \@a2, \@a3, \@a4 ] );
ok(! $LR, "Got expected subset relationship");

eval { $LR = is_LsubsetR(
    [ \@a0, \@a1, \@a2, \@a3, \@a4 ], [ 3,2 ], [ 'bogus' ]
); };
like($@, qr/Subroutine call requires 1 or 2 references as arguments/,
    "Got expected error message concerning too many arguments");

eval { $LR = is_LsubsetR(
    [ \@a0, \@a1, \@a2, \@a3, \@a4 ], [ 'bogus' , 2 ]
); };
like($@, qr/No element in index position/,
    "Got expected error message concerning bad arguments");

$eqv = is_LequivalentR( [ \@a0, \@a1, \@a2, \@a3, \@a4 ], [ 3,4 ] );
ok($eqv, "Got expected equivalence relationship");

$eqv = is_LeqvlntR( [ \@a0, \@a1, \@a2, \@a3, \@a4 ], [ 3,4 ] );
ok($eqv, "Got expected equivalence relationship");

$eqv = is_LequivalentR( [ \@a0, \@a1, \@a2, \@a3, \@a4 ], [ 2,4 ] );
ok(! $eqv, "Got expected equivalence relationship");

eval { $LR = is_LequivalentR(
    [ \@a0, \@a1, \@a2, \@a3, \@a4 ], [ 3,2 ], [ 'bogus' ]
); };
like($@, qr/Subroutine call requires 1 or 2 references as arguments/,
    "Got expected error message concerning too many arguments");

eval { $LR = is_LequivalentR(
    [ \@a0, \@a1, \@a2, \@a3, \@a4 ], [ 'bogus', 2 ]
); };
like($@, qr/No element in index position/,
    "Got expected error message concerning bad arguments");

{
    my ($rv, $stdout, $stderr);
    capture(
        sub { $rv = print_subset_chart( [ \@a0, \@a1, \@a2, \@a3, \@a4 ] ); },
        \$stdout,
    );
    ok($rv, "print_subset_chart() returned true value");
    like($stdout, qr/Subset Relationships/,
        "Got expected chart header");
}
{
    my ($rv, $stdout, $stderr);
    capture(
        sub { $rv = print_equivalence_chart( [ \@a0, \@a1, \@a2, \@a3, \@a4 ] ); },
        \$stdout,
    );
    ok($rv, "print_equivalence_chart() returned true value");
    like($stdout, qr/Equivalence Relationships/,
        "Got expected chart header");
}

@args = qw( abel baker camera delta edward fargo golfer hilton icon jerky zebra );

is_deeply(func_all_is_member_which( [ \@a0, \@a1, \@a2, \@a3, \@a4 ], \@args ),
    $test_member_which_mult,
    "is_member_which() returned all expected values");

is_deeply(func_all_is_member_which_ref( [ \@a0, \@a1, \@a2, \@a3, \@a4 ], \@args ),
    $test_member_which_mult,
    "is_member_which_ref() returned all expected values");

$memb_hash_ref = are_members_which( [ \@a0, \@a1, \@a2, \@a3, \@a4 ], \@args );
is_deeply($memb_hash_ref, $test_members_which_mult,
   "are_members_which() returned all expected values");

is_deeply(func_all_is_member_any( [ \@a0, \@a1, \@a2, \@a3, \@a4 ], \@args ),
    $test_member_any_mult,
    "is_member_any() returned all expected values");

$memb_hash_ref = are_members_any( [ \@a0, \@a1, \@a2, \@a3, \@a4 ], \@args );
ok(func_wrap_are_members_any(
    $memb_hash_ref,
    $test_members_any_mult,
), "are_members_any() returned all expected values");

$vers = get_version;
ok($vers, "get_version() returned true value");

$disj = is_LdisjointR( [ \@a0, \@a1, \@a2, \@a3, \@a4, \@a8 ] );
ok(! $disj, "Got expected disjoint relationship");

$disj = is_LdisjointR( [ \@a0, \@a1, \@a2, \@a3, \@a4, \@a8 ], [ 2,3 ] );
ok(! $disj, "Got expected disjoint relationship");

$disj = is_LdisjointR( [ \@a0, \@a1, \@a2, \@a3, \@a4, \@a8 ], [ 4,5 ] );
ok($disj, "Got expected disjoint relationship");

eval { $LR = is_LdisjointR(
    [ \@a0, \@a1, \@a2, \@a3, \@a4 ], [ 3,2 ], [ 'bogus' ]
); };
like($@, qr/Subroutine call requires 1 or 2 references as arguments/,
    "Got expected error message concerning too many arguments");

eval { $LR = is_LdisjointR(
    [ \@a0, \@a1, \@a2, \@a3, \@a4 ], [ 'bogus', 2 ]
); };
like($@, qr/No element in index position/,
    "Got expected error message concerning bad arguments");

