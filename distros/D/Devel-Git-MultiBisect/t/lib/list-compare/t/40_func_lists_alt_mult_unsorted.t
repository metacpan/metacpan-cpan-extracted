# perl
#$Id$
# 40_func_lists_alt_mult_unsorted.t
use strict;
use Test::More tests =>  42;
use List::Compare::Functional qw(:originals :aliases);
use lib ("./t");
use Test::ListCompareSpecial qw( :seen :wrap :arrays :results );
use IO::CaptureOutput qw( capture );

my @pred = ();
my %seen = ();
my %pred = ();
my @unpred = ();
my (@unique, @complement, @intersection, @union, @symmetric_difference, @bag);
my ($unique_ref, $complement_ref, $intersection_ref, $union_ref, $symmetric_difference_ref, $bag_ref);
my ($LR, $RL, $eqv, $disj, $return, $vers);
my (@nonintersection, @shared);
my ($nonintersection_ref, $shared_ref);
my ($memb_hash_ref, $memb_arr_ref, @memb_arr);
my ($unique_all_ref, $complement_all_ref, @seen);
my @args;


%pred = map {$_, 1} qw( abel baker camera delta edward fargo golfer hilton icon jerky );
@unpred = qw| kappa |;
@union = get_union( {
    lists => [ \@a0, \@a1, \@a2, \@a3, \@a4 ],
    unsorted => 1,
} );
$seen{$_}++ foreach (@union);
is_deeply(\%seen, \%pred, "unsorted:  got expected union");
ok(unseen(\%seen, \@unpred),
    "union:  All non-expected elements correctly excluded");
%seen = ();

$union_ref = get_union_ref( {
    lists => [ \@a0, \@a1, \@a2, \@a3, \@a4 ],
    unsorted => 1,
} );
$seen{$_}++ foreach (@{$union_ref});
is_deeply(\%seen, \%pred, "unsorted:  got expected union");
ok(unseen(\%seen, \@unpred),
    "union:  All non-expected elements correctly excluded");
%seen = ();

%pred = map {$_, 1} qw( baker camera delta edward fargo golfer hilton icon );
@unpred = qw| abel jerky |;
@shared = get_shared( {
    lists => [ \@a0, \@a1, \@a2, \@a3, \@a4 ],
    unsorted => 1,
} );
$seen{$_}++ foreach (@shared);
is_deeply(\%seen, \%pred, "unsorted:  got expected shared");
ok(unseen(\%seen, \@unpred),
    "shared:  All non-expected elements correctly excluded");
%seen = ();

$shared_ref = get_shared_ref( {
    lists => [ \@a0, \@a1, \@a2, \@a3, \@a4 ],
    unsorted => 1,
} );
$seen{$_}++ foreach (@{$shared_ref});
is_deeply(\%seen, \%pred, "unsorted:  got expected shared");
ok(unseen(\%seen, \@unpred),
    "shared:  All non-expected elements correctly excluded");
%seen = ();

%pred = map {$_, 1} qw( fargo golfer );
@unpred = qw| abel baker camera delta edward hilton icon jerky |;
@intersection = get_intersection( {
    lists => [ \@a0, \@a1, \@a2, \@a3, \@a4 ],
    unsorted => 1,
} );
$seen{$_}++ foreach (@intersection);
is_deeply(\%seen, \%pred, "unsorted:  got expected intersection");
ok(unseen(\%seen, \@unpred),
    "intersection:  All non-expected elements correctly excluded");
%seen = ();

$intersection_ref = get_intersection_ref( {
    lists => [ \@a0, \@a1, \@a2, \@a3, \@a4 ],
    unsorted => 1,
} );
$seen{$_}++ foreach (@{$intersection_ref});
is_deeply(\%seen, \%pred, "unsorted:  got expected intersection");
ok(unseen(\%seen, \@unpred),
    "intersection:  All non-expected elements correctly excluded");
%seen = ();

%pred = map {$_, 1} qw( jerky );
@unpred = qw| abel baker camera delta edward fargo golfer hilton icon |;
@unique = get_unique( {
    lists => [ \@a0, \@a1, \@a2, \@a3, \@a4 ],
    unsorted => 1,
    item => 2,
} );
$seen{$_}++ foreach (@unique);
is_deeply(\%seen, \%pred, "unsorted:  got expected unique");
ok(unseen(\%seen, \@unpred),
    "unique:  All non-expected elements correctly excluded");
%seen = ();

$unique_ref = get_unique_ref( {
    lists => [ \@a0, \@a1, \@a2, \@a3, \@a4 ],
    unsorted => 1,
    item => 2,
} );
$seen{$_}++ foreach (@{$unique_ref});
is_deeply(\%seen, \%pred, "unsorted:  got expected unique");
ok(unseen(\%seen, \@unpred),
    "unique:  All non-expected elements correctly excluded");
%seen = ();

@pred = (
    [ 'abel' ],
    [  ],
    [ 'jerky' ],
    [ ],
    [  ],
);
$unique_all_ref = get_unique_all( {
    lists => [ \@a0, \@a1, \@a2, \@a3, \@a4 ],
    unsorted => 1,
} );
is_deeply(
    make_array_seen_hash($unique_all_ref),
    make_array_seen_hash(\@pred),
    "Got expected values for get_complement_all()");

%pred = map {$_, 1} qw( abel icon jerky );
@unpred = qw| baker camera delta edward fargo golfer hilton |;
@complement = get_complement( {
    lists => [ \@a0, \@a1, \@a2, \@a3, \@a4 ],
    unsorted => 1,
    item => 1,
} );
$seen{$_}++ foreach (@complement);
is_deeply(\%seen, \%pred, "unsorted:  got expected complement");
ok(unseen(\%seen, \@unpred),
    "complement:  All non-expected elements correctly excluded");
%seen = ();

$complement_ref = get_complement_ref( {
    lists => [ \@a0, \@a1, \@a2, \@a3, \@a4 ],
    unsorted => 1,
    item => 1,
} );
$seen{$_}++ foreach (@{$complement_ref});
is_deeply(\%seen, \%pred, "unsorted:  got expected complement");
ok(unseen(\%seen, \@unpred),
    "complement:  All non-expected elements correctly excluded");
%seen = ();

%pred = map {$_, 1} qw( hilton icon jerky );
@unpred = qw| abel baker camera delta edward fargo golfer |;
@complement = get_complement( {
    lists => [ \@a0, \@a1, \@a2, \@a3, \@a4 ],
    unsorted => 1,
} );
$seen{$_}++ foreach (@complement);
is_deeply(\%seen, \%pred, "unsorted:  got expected complement");
ok(unseen(\%seen, \@unpred),
    "complement:  All non-expected elements correctly excluded");
%seen = ();

$complement_ref = get_complement_ref( {
    lists => [ \@a0, \@a1, \@a2, \@a3, \@a4 ],
    unsorted => 1,
} );
$seen{$_}++ foreach (@{$complement_ref});
is_deeply(\%seen, \%pred, "unsorted:  got expected complement");
ok(unseen(\%seen, \@unpred),
    "complement:  All non-expected elements correctly excluded");
%seen = ();

%pred = map {$_, 1} qw( abel jerky );
@unpred = qw| baker camera delta edward fargo golfer hilton icon |;
@symmetric_difference =
    get_symmetric_difference( {
    lists => [ \@a0, \@a1, \@a2, \@a3, \@a4 ],
    unsorted => 1,
} );
$seen{$_}++ foreach (@symmetric_difference);
is_deeply(\%seen, \%pred, "unsorted:  Got expected symmetric difference");
ok(unseen(\%seen, \@unpred),
    "symmetric difference:  All non-expected elements correctly excluded");
%seen = ();

$symmetric_difference_ref =
    get_symmetric_difference_ref( {
    lists => [ \@a0, \@a1, \@a2, \@a3, \@a4 ],
    unsorted => 1,
} );
$seen{$_}++ foreach (@{$symmetric_difference_ref});
is_deeply(\%seen, \%pred, "unsorted:  Got expected symmetric difference");
ok(unseen(\%seen, \@unpred),
    "symmetric difference:  All non-expected elements correctly excluded");
%seen = ();

@symmetric_difference = get_symdiff( {
    lists => [ \@a0, \@a1, \@a2, \@a3, \@a4 ],
    unsorted => 1,
} );
$seen{$_}++ foreach (@symmetric_difference);
is_deeply(\%seen, \%pred, "unsorted:  Got expected symmetric difference");
ok(unseen(\%seen, \@unpred),
    "symmetric difference:  All non-expected elements correctly excluded");
%seen = ();

$symmetric_difference_ref = get_symdiff_ref( {
    lists => [ \@a0, \@a1, \@a2, \@a3, \@a4 ],
    unsorted => 1,
} );
$seen{$_}++ foreach (@{$symmetric_difference_ref});
is_deeply(\%seen, \%pred, "unsorted:  Got expected symmetric difference");
ok(unseen(\%seen, \@unpred),
    "symmetric difference:  All non-expected elements correctly excluded");
%seen = ();

@pred = (
    [ qw( hilton icon jerky ) ],
    [ qw( abel icon jerky ) ],
    [ qw( abel baker camera delta edward ) ],
    [ qw( abel baker camera delta edward jerky ) ],
    [ qw( abel baker camera delta edward jerky ) ],
);
$complement_all_ref = get_complement_all( {
    lists => [ \@a0, \@a1, \@a2, \@a3, \@a4 ],
    unsorted => 1,
} );
is_deeply(
    make_array_seen_hash($complement_all_ref),
    make_array_seen_hash(\@pred),
    "Got expected values for get_complement_all()");
%seen = ();

%pred = map {$_, 1} qw( abel baker camera delta edward hilton icon jerky );
@unpred = qw| fargo golfer |;
@nonintersection = get_nonintersection( {
    lists => [ \@a0, \@a1, \@a2, \@a3, \@a4 ],
    unsorted => 1,
} );
$seen{$_}++ foreach (@nonintersection);
is_deeply(\%seen, \%pred, "unsorted:  Got expected nonintersection");
ok(unseen(\%seen, \@unpred),
    "nonintersection:  All non-expected elements correctly excluded");
%seen = ();

$nonintersection_ref =
    get_nonintersection_ref( {
    lists => [ \@a0, \@a1, \@a2, \@a3, \@a4 ],
    unsorted => 1,
} );
$seen{$_}++ foreach (@{$nonintersection_ref});
is_deeply(\%seen, \%pred, "unsorted:  Got expected nonintersection");
ok(unseen(\%seen, \@unpred),
    "nonintersection:  All non-expected elements correctly excluded");
%seen = ();

%pred = (
    abel    => 2,
    baker   => 2,
    camera  => 2,
    delta   => 3,
    edward  => 2,
    fargo   => 6,
    golfer  => 5,
    hilton  => 4,
    icon    => 5,
    jerky   => 1,
);
@unpred = qw| kappa |;
@bag = get_bag( {
    lists => [ \@a0, \@a1, \@a2, \@a3, \@a4 ],
    unsorted => 1,
} );
$seen{$_}++ foreach (@bag);
is_deeply(\%seen, \%pred, "Got predicted quantities in bag");
ok(unseen(\%seen, \@unpred),
    "bag:  All non-expected elements correctly excluded");
%seen = ();

$bag_ref = get_bag_ref( {
    lists => [ \@a0, \@a1, \@a2, \@a3, \@a4 ],
    unsorted => 1,
} );
$seen{$_}++ foreach (@{$bag_ref});
is_deeply(\%seen, \%pred, "Got predicted quantities in bag");
ok(unseen(\%seen, \@unpred),
    "bag:  All non-expected elements correctly excluded");
%seen = ();

