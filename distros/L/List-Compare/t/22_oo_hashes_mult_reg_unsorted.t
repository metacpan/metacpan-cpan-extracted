# perl
#$Id$
# 22_oo_hashes_mult_reg_unsorted.t
use strict;
use Test::More tests => 110;
use List::Compare;
use lib ("./t");
use Test::ListCompareSpecial qw( :seen :wrap :hashes :results );
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
my $lcmu   = List::Compare->new('-u', \%h0, \%h1, \%h2, \%h3, \%h4);
ok($lcmu, "List::Compare constructor returned true value");

%pred = map {$_, 1} qw( abel baker camera delta edward fargo golfer hilton icon jerky );
@unpred = qw| kappa |;
@union = $lcmu->get_union;
$seen{$_}++ foreach (@union);
is_deeply(\%seen, \%pred, "unsorted:  got expected union");
ok(unseen(\%seen, \@unpred),
    "union:  All non-expected elements correctly excluded");
%seen = ();

$union_ref = $lcmu->get_union_ref;
$seen{$_}++ foreach (@{$union_ref});
is_deeply(\%seen, \%pred, "unsorted:  got expected union");
ok(unseen(\%seen, \@unpred),
    "union:  All non-expected elements correctly excluded");
%seen = ();

%pred = map {$_, 1} qw( baker camera delta edward fargo golfer hilton icon );
@unpred = qw| abel jerky |;
@shared = $lcmu->get_shared;
$seen{$_}++ foreach (@shared);
is_deeply(\%seen, \%pred, "unsorted:  got expected shared");
ok(unseen(\%seen, \@unpred),
    "shared:  All non-expected elements correctly excluded");
%seen = ();

$shared_ref = $lcmu->get_shared_ref;
$seen{$_}++ foreach (@{$shared_ref});
is_deeply(\%seen, \%pred, "unsorted:  got expected shared");
ok(unseen(\%seen, \@unpred),
    "shared:  All non-expected elements correctly excluded");
%seen = ();

%pred = map {$_, 1} qw( fargo golfer );
@unpred = qw| abel baker camera delta edward hilton icon jerky |;
@intersection = $lcmu->get_intersection;
$seen{$_}++ foreach (@intersection);
is_deeply(\%seen, \%pred, "unsorted:  got expected intersection");
ok(unseen(\%seen, \@unpred),
    "intersection:  All non-expected elements correctly excluded");
%seen = ();

$intersection_ref = $lcmu->get_intersection_ref;
$seen{$_}++ foreach (@{$intersection_ref});
is_deeply(\%seen, \%pred, "unsorted:  got expected intersection");
ok(unseen(\%seen, \@unpred),
    "intersection:  All non-expected elements correctly excluded");
%seen = ();

%pred = map {$_, 1} qw( jerky );
@unpred = qw| abel baker camera delta edward fargo golfer hilton icon |;
@unique = $lcmu->get_unique(2);
$seen{$_}++ foreach (@unique);
is_deeply(\%seen, \%pred, "unsorted:  got expected unique");
ok(unseen(\%seen, \@unpred),
    "unique:  All non-expected elements correctly excluded");
%seen = ();

$unique_ref = $lcmu->get_unique_ref(2);
$seen{$_}++ foreach (@{$unique_ref});
is_deeply(\%seen, \%pred, "unsorted:  got expected unique");
ok(unseen(\%seen, \@unpred),
    "unique:  All non-expected elements correctly excluded");
%seen = ();

{
    my ($stdout, $stderr);
    capture(
        sub { @unique = $lcmu->get_Lonly(2); },
        \$stdout,
        \$stderr,
    );
    $seen{$_}++ foreach (@unique);
    is_deeply(\%seen, \%pred, "unsorted:  got expected unique");
    ok(unseen(\%seen, \@unpred),
        "unique:  All non-expected elements correctly excluded");
    like($stderr,
        qr/When comparing 3 or more lists, \&get_Lonly or its alias defaults/,
        "Got expected warning"
    );
}
%seen = ();

{
    my ($stdout, $stderr);
    capture(
        sub { $unique_ref = $lcmu->get_Lonly_ref(2); },
        \$stdout,
        \$stderr,
    );
    $seen{$_}++ foreach (@{$unique_ref});
    is_deeply(\%seen, \%pred, "unsorted:  got expected unique");
    ok(unseen(\%seen, \@unpred),
        "unique:  All non-expected elements correctly excluded");
    like($stderr,
        qr/When comparing 3 or more lists, \&get_Lonly_ref or its alias defaults/,
        "Got expected warning"
    );
}
%seen = ();

{
    my ($stdout, $stderr);
    capture(
        sub { @unique = $lcmu->get_Aonly(2); },
        \$stdout,
        \$stderr,
    );
    $seen{$_}++ foreach (@unique);
    is_deeply(\%seen, \%pred, "unsorted:  got expected unique");
    ok(unseen(\%seen, \@unpred),
        "unique:  All non-expected elements correctly excluded");
    like($stderr,
        qr/When comparing 3 or more lists, \&get_Lonly or its alias defaults/,
        "Got expected warning"
    );
}
%seen = ();

{
    my ($stdout, $stderr);
    capture(
        sub { $unique_ref = $lcmu->get_Aonly_ref(2); },
        \$stdout,
        \$stderr,
    );
    $seen{$_}++ foreach (@{$unique_ref});
    is_deeply(\%seen, \%pred, "unsorted:  got expected unique");
    ok(unseen(\%seen, \@unpred),
        "unique:  All non-expected elements correctly excluded");
    like($stderr,
        qr/When comparing 3 or more lists, \&get_Lonly_ref or its alias defaults/,
        "Got expected warning"
    );
}
%seen = ();

@pred = (
    [ 'abel' ],
    [  ],
    [ 'jerky' ],
    [ ],
    [  ],
);
$unique_all_ref = $lcmu->get_unique_all();
is_deeply(
    make_array_seen_hash($unique_all_ref),
    make_array_seen_hash(\@pred),
    "Got expected values for get_complement_all()");

%pred = map {$_, 1} qw( abel icon jerky );
@unpred = qw| baker camera delta edward fargo golfer hilton |;
@complement = $lcmu->get_complement(1);
$seen{$_}++ foreach (@complement);
is_deeply(\%seen, \%pred, "unsorted:  got expected complement");
ok(unseen(\%seen, \@unpred),
    "complement:  All non-expected elements correctly excluded");
%seen = ();

$complement_ref = $lcmu->get_complement_ref(1);
$seen{$_}++ foreach (@{$complement_ref});
is_deeply(\%seen, \%pred, "unsorted:  got expected complement");
ok(unseen(\%seen, \@unpred),
    "complement:  All non-expected elements correctly excluded");
%seen = ();

{
    my ($stdout, $stderr);
    capture(
        sub { @complement = $lcmu->get_Bonly(1); },
        \$stdout,
        \$stderr,
    );
    $seen{$_}++ foreach (@complement);
    is_deeply(\%seen, \%pred, "unsorted:  got expected complement");
    ok(unseen(\%seen, \@unpred),
        "complement:  All non-expected elements correctly excluded");
    like($stderr,
        qr/When comparing 3 or more lists, \&get_Ronly or its alias defaults/,
        "Got expected warning"
    );
}
%seen = ();

{
    my ($stdout, $stderr);
    capture(
        sub { $complement_ref = $lcmu->get_Bonly_ref(1); },
        \$stdout,
        \$stderr,
    );
    $seen{$_}++ foreach (@{$complement_ref});
    is_deeply(\%seen, \%pred, "unsorted:  got expected complement");
    ok(unseen(\%seen, \@unpred),
        "complement:  All non-expected elements correctly excluded");
    like($stderr,
        qr/When comparing 3 or more lists, \&get_Ronly_ref or its alias defaults/,
        "Got expected warning"
    );
}
%seen = ();

%pred = map {$_, 1} qw( hilton icon jerky );
@unpred = qw| abel baker camera delta edward fargo golfer |;
@complement = $lcmu->get_complement;
$seen{$_}++ foreach (@complement);
is_deeply(\%seen, \%pred, "unsorted:  got expected complement");
ok(unseen(\%seen, \@unpred),
    "complement:  All non-expected elements correctly excluded");
%seen = ();

$complement_ref = $lcmu->get_complement_ref;
$seen{$_}++ foreach (@{$complement_ref});
is_deeply(\%seen, \%pred, "unsorted:  got expected complement");
ok(unseen(\%seen, \@unpred),
    "complement:  All non-expected elements correctly excluded");
%seen = ();

{
    my ($stdout, $stderr);
    capture(
        sub { @complement = $lcmu->get_Ronly; },
        \$stdout,
        \$stderr,
    );
    $seen{$_}++ foreach (@complement);
    is_deeply(\%seen, \%pred, "unsorted:  got expected complement");
    ok(unseen(\%seen, \@unpred),
        "complement:  All non-expected elements correctly excluded");
    like($stderr,
        qr/When comparing 3 or more lists, \&get_Ronly or its alias defaults/,
        "Got expected warning"
    );
}
%seen = ();

{
    my ($stdout, $stderr);
    capture(
        sub { $complement_ref = $lcmu->get_Ronly_ref; },
        \$stdout,
        \$stderr,
    );
    $seen{$_}++ foreach (@{$complement_ref});
    is_deeply(\%seen, \%pred, "unsorted:  got expected complement");
    ok(unseen(\%seen, \@unpred),
        "complement:  All non-expected elements correctly excluded");
    like($stderr,
        qr/When comparing 3 or more lists, \&get_Ronly_ref or its alias defaults/,
        "Got expected warning"
    );
}
%seen = ();

{
    my ($stdout, $stderr);
    capture(
        sub { @complement = $lcmu->get_Bonly; },
        \$stdout,
        \$stderr,
    );
    $seen{$_}++ foreach (@complement);
    is_deeply(\%seen, \%pred, "unsorted:  got expected complement");
    ok(unseen(\%seen, \@unpred),
        "complement:  All non-expected elements correctly excluded");
    like($stderr,
        qr/When comparing 3 or more lists, \&get_Ronly or its alias defaults/,
        "Got expected warning"
    );
}
%seen = ();

{
    my ($stdout, $stderr);
    capture(
        sub { $complement_ref = $lcmu->get_Bonly_ref; },
        \$stdout,
        \$stderr,
    );
    $seen{$_}++ foreach (@{$complement_ref});
    is_deeply(\%seen, \%pred, "unsorted:  got expected complement");
    ok(unseen(\%seen, \@unpred),
        "complement:  All non-expected elements correctly excluded");
    like($stderr,
        qr/When comparing 3 or more lists, \&get_Ronly_ref or its alias defaults/,
        "Got expected warning"
    );
}
%seen = ();

%pred = map {$_, 1} qw( abel jerky );
@unpred = qw| baker camera delta edward fargo golfer hilton icon |;
@symmetric_difference = $lcmu->get_symmetric_difference;
$seen{$_}++ foreach (@symmetric_difference);
is_deeply(\%seen, \%pred, "unsorted:  Got expected symmetric difference");
ok(unseen(\%seen, \@unpred),
    "symmetric difference:  All non-expected elements correctly excluded");
%seen = ();

$symmetric_difference_ref = $lcmu->get_symmetric_difference_ref;
$seen{$_}++ foreach (@{$symmetric_difference_ref});
is_deeply(\%seen, \%pred, "unsorted:  Got expected symmetric difference");
ok(unseen(\%seen, \@unpred),
    "symmetric difference:  All non-expected elements correctly excluded");
%seen = ();

@symmetric_difference = $lcmu->get_symdiff;
$seen{$_}++ foreach (@symmetric_difference);
is_deeply(\%seen, \%pred, "unsorted:  Got expected symmetric difference");
ok(unseen(\%seen, \@unpred),
    "symmetric difference:  All non-expected elements correctly excluded");
%seen = ();

$symmetric_difference_ref = $lcmu->get_symdiff_ref;
$seen{$_}++ foreach (@{$symmetric_difference_ref});
is_deeply(\%seen, \%pred, "unsorted:  Got expected symmetric difference");
ok(unseen(\%seen, \@unpred),
    "symmetric difference:  All non-expected elements correctly excluded");
%seen = ();

{
    my ($stdout, $stderr);
    capture(
        sub { @symmetric_difference = $lcmu->get_LorRonly; },
        \$stdout,
        \$stderr,
    );
    $seen{$_}++ foreach (@symmetric_difference);
    is_deeply(\%seen, \%pred, "unsorted:  Got expected symmetric difference");
    ok(unseen(\%seen, \@unpred),
        "symmetric difference:  All non-expected elements correctly excluded");
    like($stderr,
        qr/When comparing 3 or more lists, \&get_LorRonly or its alias defaults/,
        "Got expected warning",
    );
}
%seen = ();

{
    my ($stdout, $stderr);
    capture(
        sub { $symmetric_difference_ref = $lcmu->get_LorRonly_ref; },
        \$stdout,
        \$stderr,
    );
    $seen{$_}++ foreach (@{$symmetric_difference_ref});
    is_deeply(\%seen, \%pred, "unsorted:  Got expected symmetric difference");
    ok(unseen(\%seen, \@unpred),
        "symmetric difference:  All non-expected elements correctly excluded");
}
%seen = ();

{
    my ($stdout, $stderr);
    capture(
        sub { @symmetric_difference = $lcmu->get_AorBonly; },
        \$stdout,
        \$stderr,
    );
    $seen{$_}++ foreach (@symmetric_difference);
    is_deeply(\%seen, \%pred, "unsorted:  Got expected symmetric difference");
    ok(unseen(\%seen, \@unpred),
        "symmetric difference:  All non-expected elements correctly excluded");
    like($stderr,
        qr/When comparing 3 or more lists, \&get_LorRonly or its alias defaults/,
        "Got expected warning",
    );
}
%seen = ();

{
    my ($stdout, $stderr);
    capture(
        sub { $symmetric_difference_ref = $lcmu->get_AorBonly_ref; },
        \$stdout,
        \$stderr,
    );
    $seen{$_}++ foreach (@{$symmetric_difference_ref});
    is_deeply(\%seen, \%pred, "unsorted:  Got expected symmetric difference");
    ok(unseen(\%seen, \@unpred),
        "symmetric difference:  All non-expected elements correctly excluded");
}
%seen = ();

@pred = (
    [ qw( hilton icon jerky ) ],
    [ qw( abel icon jerky ) ],
    [ qw( abel baker camera delta edward ) ],
    [ qw( abel baker camera delta edward jerky ) ],
    [ qw( abel baker camera delta edward jerky ) ],
);
$complement_all_ref = $lcmu->get_complement_all();
is_deeply(
    make_array_seen_hash($complement_all_ref),
    make_array_seen_hash(\@pred),
    "Got expected values for get_complement_all()");
%seen = ();

%pred = map {$_, 1} qw( abel baker camera delta edward hilton icon jerky );
@unpred = qw| fargo golfer |;
@nonintersection = $lcmu->get_nonintersection;
$seen{$_}++ foreach (@nonintersection);
is_deeply(\%seen, \%pred, "unsorted:  Got expected nonintersection");
ok(unseen(\%seen, \@unpred),
    "nonintersection:  All non-expected elements correctly excluded");
%seen = ();

$nonintersection_ref = $lcmu->get_nonintersection_ref;
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
@bag = $lcmu->get_bag;
$seen{$_}++ foreach (@bag);
is_deeply(\%seen, \%pred, "Got predicted quantities in bag");
ok(unseen(\%seen, \@unpred),
    "bag:  All non-expected elements correctly excluded");
%seen = ();

$bag_ref = $lcmu->get_bag_ref;
$seen{$_}++ foreach (@{$bag_ref});
is_deeply(\%seen, \%pred, "Got predicted quantities in bag");
ok(unseen(\%seen, \@unpred),
    "bag:  All non-expected elements correctly excluded");
%seen = ();

$LR = $lcmu->is_LsubsetR(3,2);
ok($LR, "Got expected subset relationship");

$LR = $lcmu->is_AsubsetB(3,2);
ok($LR, "Got expected subset relationship");

$LR = $lcmu->is_LsubsetR(2,3);
ok(! $LR, "Got expected subset relationship");

$LR = $lcmu->is_AsubsetB(2,3);
ok(! $LR, "Got expected subset relationship");

$LR = $lcmu->is_LsubsetR;
ok(! $LR, "Got expected subset relationship");

{
    my ($rv, $stdout, $stderr);
    capture(
        sub { $RL = $lcmu->is_RsubsetL; },
        \$stdout,
        \$stderr,
    );
    ok(! $RL, "Got expected subset relationship");
    like($stderr,
        qr/When comparing 3 or more lists, \&is_RsubsetL or its alias is restricted/,
        "Got expected warning",
    );
}
{
    my ($rv, $stdout, $stderr);
    capture(
        sub { $RL = $lcmu->is_BsubsetA; },
        \$stdout,
        \$stderr,
    );
    ok(! $RL, "Got expected subset relationship");
    like($stderr,
        qr/When comparing 3 or more lists, \&is_RsubsetL or its alias is restricted/,
        "Got expected warning",
    );
}

$eqv = $lcmu->is_LequivalentR(3,4);
ok($eqv, "Got expected equivalence relationship");

$eqv = $lcmu->is_LeqvlntR(3,4);
ok($eqv, "Got expected equivalence relationship");

$eqv = $lcmu->is_LequivalentR(2,4);
ok(! $eqv, "Got expected equivalence relationship");

{
    my ($rv, $stdout, $stderr);
    capture(
        sub { $rv = $lcmu->print_subset_chart; },
        \$stdout,
    );
    ok($rv, "print_subset_chart() returned true value");
    like($stdout, qr/Subset Relationships/,
        "Got expected chart header");
}
{
    my ($rv, $stdout, $stderr);
    capture(
        sub { $rv = $lcmu->print_equivalence_chart; },
        \$stdout,
    );
    ok($rv, "print_equivalence_chart() returned true value");
    like($stdout, qr/Equivalence Relationships/,
        "Got expected chart header");
}

@args = qw( abel baker camera delta edward fargo golfer hilton icon jerky zebra );
is_deeply( all_is_member_which( $lcmu, \@args), $test_member_which_mult,
    "is_member_which() returned all expected values");

is_deeply( all_is_member_which_ref( $lcmu, \@args), $test_member_which_mult,
    "is_member_which_ref() returned all expected values");

$memb_hash_ref = $lcmu->are_members_which(
    [ qw| abel baker camera delta edward fargo
          golfer hilton icon jerky zebra | ] );
is_deeply($memb_hash_ref, $test_members_which_mult,
   "are_members_which() returned all expected values");

is_deeply( all_is_member_any( $lcmu, \@args), $test_member_any_mult,
    "is_member_which() returned all expected values");

$memb_hash_ref = $lcmu->are_members_any(
    [ qw| abel baker camera delta edward fargo
          golfer hilton icon jerky zebra | ] );
is_deeply($memb_hash_ref, $test_members_any_mult,
    "are_members_any() returned all expected values");

$vers = $lcmu->get_version;
ok($vers, "get_version() returned true value");

### new ###
my $lcmu_dj   = List::Compare->new(\%h0, \%h1, \%h2, \%h3, \%h4, \%h8);
ok($lcmu_dj, "List::Compare constructor returned true value");

$disj = $lcmu_dj->is_LdisjointR;
ok(! $disj, "Got expected disjoint relationship");

$disj = $lcmu_dj->is_LdisjointR(2,3);
ok(! $disj, "Got expected disjoint relationship");

$disj = $lcmu_dj->is_LdisjointR(4,5);
ok($disj, "Got expected disjoint relationship");

########## BELOW:  Test for '--unsorted' option ##########

my $lcmun   = List::Compare->new('--unsorted', \%h0, \%h1, \%h2, \%h3, \%h4);
ok($lcmu_dj, "List::Compare constructor returned true value");
