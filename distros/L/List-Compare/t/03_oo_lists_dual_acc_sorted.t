# perl
#$Id$
# 03_oo_lists_dual_acc_sorted.t
use strict;
use Test::More tests =>  86;
use List::Compare;
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

### new ###
my $lc   = List::Compare->new('-a', \@a0, \@a1);
ok($lc, "List::Compare constructor returned true value");

@pred = qw(abel baker camera delta edward fargo golfer hilton);
@union = $lc->get_union;
is_deeply( \@union, \@pred, "Got expected union");

$union_ref = $lc->get_union_ref;
is_deeply( $union_ref, \@pred, "Got expected union");

{
    my ($rv, $stdout, $stderr);
    capture(
        sub { @shared = $lc->get_shared; },
        \$stdout,
        \$stderr,
    );
    is_deeply( \@shared, \@pred, "Got expected shared");
    like($stderr, qr/please consider re-coding/,
        "Got expected warning");
}
{
    my ($rv, $stdout, $stderr);
    capture(
        sub { $shared_ref = $lc->get_shared_ref; },
        \$stdout,
        \$stderr,
    );
    is_deeply( $shared_ref, \@pred, "Got expected shared");
    like($stderr, qr/please consider re-coding/,
        "Got expected warning");
}

@pred = qw( baker camera delta edward fargo golfer );
@intersection = $lc->get_intersection;
is_deeply(\@intersection, \@pred, "Got expected intersection");

$intersection_ref = $lc->get_intersection_ref;
is_deeply($intersection_ref, \@pred, "Got expected intersection");

@pred = qw( abel );
@unique = $lc->get_unique;
is_deeply(\@unique, \@pred, "Got expected unique");

$unique_ref = $lc->get_unique_ref;
is_deeply($unique_ref, \@pred, "Got expected unique");

@unique = $lc->get_Lonly;
is_deeply(\@unique, \@pred, "Got expected unique");

$unique_ref = $lc->get_Lonly_ref;
is_deeply($unique_ref, \@pred, "Got expected unique");

@unique = $lc->get_Aonly;
is_deeply(\@unique, \@pred, "Got expected unique");

$unique_ref = $lc->get_Aonly_ref;
is_deeply($unique_ref, \@pred, "Got expected unique");

@pred = (
    [ 'abel' ],
    [ 'hilton' ],
);
$unique_all_ref = $lc->get_unique_all();
is_deeply(
    make_array_seen_hash($unique_all_ref),
    make_array_seen_hash(\@pred),
    "Got expected values for get_unique_all()");

@pred = qw ( hilton );
@complement = $lc->get_complement;
is_deeply(\@complement, \@pred, "Got expected complement");

$complement_ref = $lc->get_complement_ref;
is_deeply($complement_ref, \@pred, "Got expected complement");

@complement = $lc->get_Ronly;
is_deeply(\@complement, \@pred, "Got expected complement");

$complement_ref = $lc->get_Ronly_ref;
is_deeply($complement_ref, \@pred, "Got expected complement");

@complement = $lc->get_Bonly;
is_deeply(\@complement, \@pred, "Got expected complement");

$complement_ref = $lc->get_Bonly_ref;
is_deeply($complement_ref, \@pred, "Got expected complement");

@pred = (
    [ qw( hilton ) ],
    [ qw( abel ) ],
);
$complement_all_ref = $lc->get_complement_all();
is_deeply(
    make_array_seen_hash($complement_all_ref),
    make_array_seen_hash(\@pred),
    "Got expected values for get_complement_all()");

@pred = qw( abel hilton );
@symmetric_difference = $lc->get_symmetric_difference;
is_deeply(\@symmetric_difference, \@pred, "Got expected symmetric_difference");

$symmetric_difference_ref = $lc->get_symmetric_difference_ref;
is_deeply($symmetric_difference_ref, \@pred, "Got expected symmetric_difference");

@symmetric_difference = $lc->get_symdiff;
is_deeply(\@symmetric_difference, \@pred, "Got expected symmetric_difference");

$symmetric_difference_ref = $lc->get_symdiff_ref;
is_deeply($symmetric_difference_ref, \@pred, "Got expected symmetric_difference");

@symmetric_difference = $lc->get_LorRonly;
is_deeply(\@symmetric_difference, \@pred, "Got expected symmetric_difference");

$symmetric_difference_ref = $lc->get_LorRonly_ref;
is_deeply($symmetric_difference_ref, \@pred, "Got expected symmetric_difference");

@symmetric_difference = $lc->get_AorBonly;
is_deeply(\@symmetric_difference, \@pred, "Got expected symmetric_difference");

$symmetric_difference_ref = $lc->get_AorBonly_ref;
is_deeply($symmetric_difference_ref, \@pred, "Got expected symmetric_difference");

@pred = qw( abel hilton );
{
    my ($rv, $stdout, $stderr);
    capture(
        sub { @nonintersection = $lc->get_nonintersection; },
        \$stdout,
        \$stderr,
    );
    is_deeply( \@nonintersection, \@pred, "Got expected nonintersection");
    like($stderr, qr/please consider re-coding/,
        "Got expected warning");
}
{
    my ($rv, $stdout, $stderr);
    capture(
        sub { $nonintersection_ref = $lc->get_nonintersection_ref; },
        \$stdout,
        \$stderr,
    );
    is_deeply($nonintersection_ref, \@pred, "Got expected nonintersection");
    like($stderr, qr/please consider re-coding/,
        "Got expected warning");
}

@pred = qw( abel abel baker baker camera camera delta delta delta edward
edward fargo fargo golfer golfer hilton );
@bag = $lc->get_bag;
is_deeply(\@bag, \@pred, "Got expected bag");

$bag_ref = $lc->get_bag_ref;
is_deeply($bag_ref, \@pred, "Got expected bag");

$LR = $lc->is_LsubsetR;
ok(! $LR, "Got expected subset relationship");

$LR = $lc->is_AsubsetB;
ok(! $LR, "Got expected subset relationship");

$RL = $lc->is_RsubsetL;
ok(! $RL, "Got expected subset relationship");

$RL = $lc->is_BsubsetA;
ok(! $RL, "Got expected subset relationship");

$eqv = $lc->is_LequivalentR;
ok(! $eqv, "Got expected equivalent relationship");

$eqv = $lc->is_LeqvlntR;
ok(! $eqv, "Got expected equivalent relationship");

$disj = $lc->is_LdisjointR;
ok(! $disj, "Got expected disjoint relationship");

{
    my ($rv, $stdout, $stderr);
    capture(
        sub { $rv = $lc->print_subset_chart; },
        \$stdout,
    );
    ok($rv, "print_subset_chart() returned true value");
    like($stdout, qr/Subset Relationships/,
        "Got expected chart header");
}
{
    my ($rv, $stdout, $stderr);
    capture(
        sub { $rv = $lc->print_equivalence_chart; },
        \$stdout,
    );
    ok($rv, "print_equivalence_chart() returned true value");
    like($stdout, qr/Equivalence Relationships/,
        "Got expected chart header");
}
     
ok(wrap_is_member_which(
    $lc,
    $test_members_which,
), "is_member_which() returned all expected values");

eval { $memb_arr_ref = $lc->is_member_which('jerky', 'zebra') };
like($@, qr/Method call requires exactly 1 argument \(no references\)/,
        "is_member_which() correctly generated error message");

ok(wrap_is_member_which_ref(
    $lc,
    $test_members_which,
), "is_member_which_ref() returned all expected values");

eval { $memb_arr_ref = $lc->is_member_which_ref('jerky', 'zebra') };
like($@, qr/Method call requires exactly 1 argument \(no references\)/,
        "is_member_which_ref() correctly generated error message");

eval { $memb_arr_ref = $lc->is_member_which_ref( [ 'jerky' ] ) };
like($@, qr/Method call requires exactly 1 argument \(no references\)/,
        "is_member_which_ref() correctly generated error message");

@args = qw( abel baker camera delta edward fargo golfer hilton icon jerky zebra );
$memb_hash_ref = $lc->are_members_which( \@args );
ok(wrap_are_members_which(
    $memb_hash_ref,
    $test_members_which,
), "are_members_which() returned all expected value");

eval { $memb_hash_ref = $lc->are_members_which( { key => 'value' } ) };
like($@,
    qr/Method call requires exactly 1 argument which must be an array reference/,
    "are_members_which() correctly generated error message");

eval { $memb_hash_ref = $lc->are_members_which( \@args, [ 1 .. 3 ] ) };
like($@,
    qr/Method call requires exactly 1 argument which must be an array reference/,
    "are_members_which() correctly generated error message");

ok(wrap_is_member_any(
    $lc,
    $test_members_any,
), "is_member_any() returned all expected values");

eval { $lc->is_member_any('jerky', 'zebra') };
like($@,
    qr/Method call requires exactly 1 argument \(no references\)/,
    "is_member_any() correctly generated error message");

eval { $lc->is_member_any( [ 'jerky' ] ) };
like($@,
    qr/Method call requires exactly 1 argument \(no references\)/,
    "is_member_any() correctly generated error message");

$memb_hash_ref = $lc->are_members_any( \@args );
ok(wrap_are_members_any(
    $memb_hash_ref,
    $test_members_any,
), "are_members_any() returned all expected values");

eval { $memb_hash_ref = $lc->are_members_any( { key => 'value' } ) };
like($@,
    qr/Method call requires exactly 1 argument which must be an array reference/,
    "are_members_any() correctly generated error message");

eval { $memb_hash_ref = $lc->are_members_any( \@args, [ 1..3 ] ) };
like($@,
    qr/Method call requires exactly 1 argument which must be an array reference/,
    "are_members_any() correctly generated error message");

$vers = $lc->get_version;
ok($vers, "get_version() returned true value");

### new ###
my $lc_s  = List::Compare->new('-a', \@a2, \@a3);
ok($lc_s, "constructor returned true value");

$LR = $lc_s->is_LsubsetR;
ok(! $LR, "non-subset correctly determined");

$LR = $lc_s->is_AsubsetB;
ok(! $LR, "non-subset correctly determined");

$RL = $lc_s->is_RsubsetL;
ok($RL, "subset correctly determined");

$RL = $lc_s->is_BsubsetA;
ok($RL, "subset correctly determined");

$eqv = $lc_s->is_LequivalentR;
ok(! $eqv, "non-equivalence correctly determined");

$eqv = $lc_s->is_LeqvlntR;
ok(! $eqv, "non-equivalence correctly determined");

$disj = $lc_s->is_LdisjointR;
ok(! $disj, "non-disjoint correctly determined");

### new ###
my $lc_e  = List::Compare->new('-a', \@a3, \@a4);
ok($lc_e, "constructor returned true value");

$eqv = $lc_e->is_LequivalentR;
ok($eqv, "equivalence correctly determined");

$eqv = $lc_e->is_LeqvlntR;
ok($eqv, "equivalence correctly determined");

$disj = $lc_e->is_LdisjointR;
ok(! $disj, "non-disjoint correctly determined");

### new ###
my $lc_dj  = List::Compare->new('-a', \@a4, \@a8);
ok($lc_dj, "constructor returned true value");

ok(0 == $lc_dj->get_intersection, "no intersection, as expected");
ok(0 == scalar(@{$lc_dj->get_intersection_ref}),
    "no intersection, as expected");
$disj = $lc_dj->is_LdisjointR;
ok($disj, "disjoint correctly determined");

########## BELOW:  Tests for '--accelerated' option ##########

my $lcacc   = List::Compare->new('--accelerated', \@a0, \@a1);
ok($lcacc, "Constructor worked with --accelerated option");

my $lcacc_s  = List::Compare->new('--accelerated', \@a2, \@a3);
ok($lcacc_s, "Constructor worked with --accelerated option");

my $lcacc_e  = List::Compare->new('--accelerated', \@a3, \@a4);
ok($lcacc_e, "Constructor worked with --accelerated option");

########## BELOW:  Test for bad arguments to constructor ##########

my ($lc_bad);
my %h5 = (
    golfer   => 1,
    lambda   => 0,
);

eval { $lc_bad = List::Compare->new('-a', \@a0, \%h5) };
like($@, qr/Must pass all array references or all hash references/,
    "Got expected error message from bad constructor");

eval { $lc_bad = List::Compare->new('-a', \%h5, \@a0) };
like($@, qr/Must pass all array references or all hash references/,
    "Got expected error message from bad constructor");

my $scalar = 'test';
eval { $lc_bad = List::Compare->new('-a', \$scalar, \@a0) };
like($@, qr/Must pass all array references or all hash references/,
    "Got expected error message from bad constructor");

eval { $lc_bad = List::Compare->new('-a', \@a0) };
like($@, qr/Must pass at least 2 references/,
    "Got expected error message from bad constructor");
