# perl
#$Id$
# 21_oo_hashes_mult_reg_sorted.t
use strict;
use Test::More tests => 104;
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
my $lcm   = List::Compare->new(\%h0, \%h1, \%h2, \%h3, \%h4);
ok($lcm, "List::Compare constructor returned true value");

@pred = qw(abel baker camera delta edward fargo golfer hilton icon jerky);
@union = $lcm->get_union;
is_deeply( \@union, \@pred, "Got expected union");

$union_ref = $lcm->get_union_ref;
is_deeply( $union_ref, \@pred, "Got expected union");

@pred = qw(baker camera delta edward fargo golfer hilton icon);
@shared = $lcm->get_shared;
is_deeply( \@shared, \@pred, "Got expected shared");

$shared_ref = $lcm->get_shared_ref;
is_deeply( $shared_ref, \@pred, "Got expected shared");

@pred = qw(fargo golfer);
@intersection = $lcm->get_intersection;
is_deeply(\@intersection, \@pred, "Got expected intersection");

$intersection_ref = $lcm->get_intersection_ref;
is_deeply($intersection_ref, \@pred, "Got expected intersection");

@pred = qw( jerky );
@unique = $lcm->get_unique(2);
is_deeply(\@unique, \@pred, "Got expected unique");

$unique_ref = $lcm->get_unique_ref(2);
is_deeply($unique_ref, \@pred, "Got expected unique");

eval { $unique_ref = $lcm->get_unique_ref('jerky') };
like($@,
    qr/Argument to method List::Compare::Multiple::get_unique_ref must be the array index/,
    "Got expected error message"
);

{
    my ($rv, $stdout, $stderr);
    capture(
        sub { @unique = $lcm->get_Lonly(2); },
        \$stdout,
        \$stderr,
    );
    is_deeply(\@unique, \@pred, "Got expected unique");
    like($stderr,
        qr/When comparing 3 or more lists, \&get_Lonly or its alias defaults/,
        "Got expected warning",
    );
}
{
    my ($rv, $stdout, $stderr);
    capture(
        sub { $unique_ref = $lcm->get_Lonly_ref(2); },
        \$stdout,
        \$stderr,
    );
    is_deeply($unique_ref, \@pred, "Got expected unique");
    like($stderr,
        qr/When comparing 3 or more lists, \&get_Lonly_ref or its alias defaults/,
        "Got expected warning",
    );
}
{
    my ($rv, $stdout, $stderr);
    capture(
        sub { @unique = $lcm->get_Aonly(2); },
        \$stdout,
        \$stderr,
    );
    is_deeply(\@unique, \@pred, "Got expected unique");
    like($stderr,
        qr/When comparing 3 or more lists, \&get_Lonly or its alias defaults/,
        "Got expected warning",
    );
}
{
    my ($rv, $stdout, $stderr);
    capture(
        sub { $unique_ref = $lcm->get_Aonly_ref(2); },
        \$stdout,
        \$stderr,
    );
    is_deeply($unique_ref, \@pred, "Got expected unique");
    like($stderr,
        qr/When comparing 3 or more lists, \&get_Lonly_ref or its alias defaults/,
        "Got expected warning",
    );
}

@pred = qw( abel );
@unique = $lcm->get_unique;
is_deeply(\@unique, \@pred, "Got expected unique");

$unique_ref = $lcm->get_unique_ref;
is_deeply($unique_ref, \@pred, "Got expected unique");

{
    my ($rv, $stdout, $stderr);
    capture(
        sub { @unique = $lcm->get_Lonly(); },
        \$stdout,
        \$stderr,
    );
    is_deeply(\@unique, \@pred, "Got expected unique");
    like($stderr,
        qr/When comparing 3 or more lists, \&get_Lonly or its alias defaults/,
        "Got expected warning",
    );
}
{
    my ($rv, $stdout, $stderr);
    capture(
        sub { $unique_ref = $lcm->get_Lonly_ref(); },
        \$stdout,
        \$stderr,
    );
    is_deeply($unique_ref, \@pred, "Got expected unique");
    like($stderr,
        qr/When comparing 3 or more lists, \&get_Lonly_ref or its alias defaults/,
        "Got expected warning",
    );
}
{
    my ($rv, $stdout, $stderr);
    capture(
        sub { @unique = $lcm->get_Aonly(); },
        \$stdout,
        \$stderr,
    );
    is_deeply(\@unique, \@pred, "Got expected unique");
    like($stderr,
        qr/When comparing 3 or more lists, \&get_Lonly or its alias defaults/,
        "Got expected warning",
    );
}
{
    my ($rv, $stdout, $stderr);
    capture(
        sub { $unique_ref = $lcm->get_Aonly_ref(); },
        \$stdout,
        \$stderr,
    );
    is_deeply($unique_ref, \@pred, "Got expected unique");
    like($stderr,
        qr/When comparing 3 or more lists, \&get_Lonly_ref or its alias defaults/,
        "Got expected warning",
    );
}

@pred = (
    [ 'abel' ],
    [  ],
    [ 'jerky' ],
    [ ],
    [  ],
);
$unique_all_ref = $lcm->get_unique_all();
is_deeply($unique_all_ref, [ @pred ],
    "Got expected values for get_unique_all()");

@pred = qw( abel icon jerky );
@complement = $lcm->get_complement(1);
is_deeply(\@complement, \@pred, "Got expected complement");

$complement_ref = $lcm->get_complement_ref(1);
is_deeply($complement_ref, \@pred, "Got expected complement");

eval { $complement_ref = $lcm->get_complement_ref('jerky') };
like($@,
    qr/Argument to method List::Compare::Multiple::get_complement_ref must be the array index/,
    "Got expected error message"
);

{
    my ($rv, $stdout, $stderr);
    capture(
        sub { @complement = $lcm->get_Ronly(1); },
        \$stdout,
        \$stderr,
    );
    is_deeply(\@complement, \@pred, "Got expected complement");
    like($stderr,
        qr/When comparing 3 or more lists, \&get_Ronly or its alias defaults/,
        "Got expected warning",
    );
}
{
    my ($rv, $stdout, $stderr);
    capture(
        sub { $complement_ref = $lcm->get_Ronly_ref(1); },
        \$stdout,
        \$stderr,
    );
    is_deeply($complement_ref, \@pred, "Got expected complement");
    like($stderr,
        qr/When comparing 3 or more lists, \&get_Ronly_ref or its alias defaults/,
        "Got expected warning",
    );
}
{
    my ($rv, $stdout, $stderr);
    capture(
        sub { @complement = $lcm->get_Bonly(1); },
        \$stdout,
        \$stderr,
    );
    is_deeply(\@complement, \@pred, "Got expected complement");
    like($stderr,
        qr/When comparing 3 or more lists, \&get_Ronly or its alias defaults/,
        "Got expected warning",
    );
}
{
    my ($rv, $stdout, $stderr);
    capture(
        sub { $complement_ref = $lcm->get_Bonly_ref(1); },
        \$stdout,
        \$stderr,
    );
    is_deeply($complement_ref, \@pred, "Got expected complement");
    like($stderr,
        qr/When comparing 3 or more lists, \&get_Ronly_ref or its alias defaults/,
        "Got expected warning",
    );
}

@pred = qw ( hilton icon jerky );
@complement = $lcm->get_complement;
is_deeply(\@complement, \@pred, "Got expected complement");

$complement_ref = $lcm->get_complement_ref;
is_deeply($complement_ref, \@pred, "Got expected complement");

{
    my ($rv, $stdout, $stderr);
    capture(
        sub { @complement = $lcm->get_Ronly(); },
        \$stdout,
        \$stderr,
    );
    is_deeply(\@complement, \@pred, "Got expected complement");
    like($stderr,
        qr/When comparing 3 or more lists, \&get_Ronly or its alias defaults/,
        "Got expected warning",
    );
}
{
    my ($rv, $stdout, $stderr);
    capture(
        sub { $complement_ref = $lcm->get_Ronly_ref(); },
        \$stdout,
        \$stderr,
    );
    is_deeply($complement_ref, \@pred, "Got expected complement");
    like($stderr,
        qr/When comparing 3 or more lists, \&get_Ronly_ref or its alias defaults/,
        "Got expected warning",
    );
}
{
    my ($rv, $stdout, $stderr);
    capture(
        sub { @complement = $lcm->get_Bonly(); },
        \$stdout,
        \$stderr,
    );
    is_deeply(\@complement, \@pred, "Got expected complement");
    like($stderr,
        qr/When comparing 3 or more lists, \&get_Ronly or its alias defaults/,
        "Got expected warning",
    );
}
{
    my ($rv, $stdout, $stderr);
    capture(
        sub { $complement_ref = $lcm->get_Bonly_ref(); },
        \$stdout,
        \$stderr,
    );
    is_deeply($complement_ref, \@pred, "Got expected complement");
    like($stderr,
        qr/When comparing 3 or more lists, \&get_Ronly_ref or its alias defaults/,
        "Got expected warning",
    );
}

@pred = (
    [ qw( hilton icon jerky ) ],
    [ qw( abel icon jerky ) ],
    [ qw( abel baker camera delta edward ) ],
    [ qw( abel baker camera delta edward jerky ) ],
    [ qw( abel baker camera delta edward jerky ) ],
);
$complement_all_ref = $lcm->get_complement_all();
is_deeply($complement_all_ref, [ @pred ],
    "Got expected values for get_complement_all()");

@pred = qw( abel jerky );
@symmetric_difference = $lcm->get_symmetric_difference;
is_deeply(\@symmetric_difference, \@pred, "Got expected symmetric_difference");

$symmetric_difference_ref = $lcm->get_symmetric_difference_ref;
is_deeply($symmetric_difference_ref, \@pred, "Got expected symmetric_difference");

@symmetric_difference = $lcm->get_symdiff;
is_deeply(\@symmetric_difference, \@pred, "Got expected symmetric_difference");

$symmetric_difference_ref = $lcm->get_symdiff_ref;
is_deeply($symmetric_difference_ref, \@pred, "Got expected symmetric_difference");

{
    my ($rv, $stdout, $stderr);
    capture(
        sub { @symmetric_difference = $lcm->get_LorRonly; },
        \$stdout,
        \$stderr,
    );
    is_deeply(\@symmetric_difference, \@pred, "Got expected symmetric_difference");
    like($stderr,
        qr/When comparing 3 or more lists, \&get_LorRonly or its alias defaults/,
        "Got expected warning",
    );
}
{
    my ($rv, $stdout, $stderr);
    capture(
        sub { $symmetric_difference_ref = $lcm->get_LorRonly_ref; },
        \$stdout,
        \$stderr,
    );
    is_deeply($symmetric_difference_ref, \@pred, "Got expected symmetric_difference");
    like($stderr,
        qr/When comparing 3 or more lists, \&get_LorRonly_ref or its alias defaults/,
        "Got expected warning",
    );
}
{
    my ($rv, $stdout, $stderr);
    capture(
        sub { @symmetric_difference = $lcm->get_AorBonly; },
        \$stdout,
        \$stderr,
    );
    is_deeply(\@symmetric_difference, \@pred, "Got expected symmetric_difference");
    like($stderr,
        qr/When comparing 3 or more lists, \&get_LorRonly or its alias defaults/,
        "Got expected warning",
    );
}
{
    my ($rv, $stdout, $stderr);
    capture(
        sub { $symmetric_difference_ref = $lcm->get_AorBonly_ref; },
        \$stdout,
        \$stderr,
    );
    is_deeply($symmetric_difference_ref, \@pred, "Got expected symmetric_difference");
    like($stderr,
        qr/When comparing 3 or more lists, \&get_LorRonly_ref or its alias defaults/,
        "Got expected warning",
    );
}

@pred = qw( abel baker camera delta edward hilton icon jerky );
@nonintersection = $lcm->get_nonintersection;
is_deeply( \@nonintersection, \@pred, "Got expected nonintersection");

$nonintersection_ref = $lcm->get_nonintersection_ref;
is_deeply($nonintersection_ref, \@pred, "Got expected nonintersection");

@pred = qw( abel abel baker baker camera camera delta delta delta edward
edward fargo fargo fargo fargo fargo fargo golfer golfer golfer golfer golfer
hilton hilton hilton hilton icon icon icon icon icon jerky );
@bag = $lcm->get_bag;
is_deeply(\@bag, \@pred, "Got expected bag");

$bag_ref = $lcm->get_bag_ref;
is_deeply($bag_ref, \@pred, "Got expected bag");

$LR = $lcm->is_LsubsetR(3,2);
ok($LR, "Got expected subset relationship");

$LR = $lcm->is_AsubsetB(3,2);
ok($LR, "Got expected subset relationship");

$LR = $lcm->is_LsubsetR(2,3);
ok(! $LR, "Got expected subset relationship");

$LR = $lcm->is_AsubsetB(2,3);
ok(! $LR, "Got expected subset relationship");

$LR = $lcm->is_LsubsetR;
ok(! $LR, "Got expected subset relationship");

eval { $LR = $lcm->is_LsubsetR(2) };
like($@,
    qr/Method List::Compare::Multiple::is_LsubsetR requires 2 arguments/,
    "Got expected error message"
);

eval { $LR = $lcm->is_LsubsetR(8,9) };
like($@,
    qr/Each argument to method List::Compare::Multiple::is_LsubsetR must be a valid array index /,
    "Got expected error message"
);

{
    my ($rv, $stdout, $stderr);
    capture(
        sub { $RL = $lcm->is_RsubsetL; },
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
        sub { $RL = $lcm->is_BsubsetA; },
        \$stdout,
        \$stderr,
    );
    ok(! $RL, "Got expected subset relationship");
    like($stderr,
        qr/When comparing 3 or more lists, \&is_RsubsetL or its alias is restricted/,
        "Got expected warning",
    );
}

$eqv = $lcm->is_LequivalentR(3,4);
ok($eqv, "Got expected equivalence relationship");

$eqv = $lcm->is_LeqvlntR(3,4);
ok($eqv, "Got expected equivalence relationship");

$eqv = $lcm->is_LequivalentR(2,4);
ok(! $eqv, "Got expected equivalence relationship");

eval { $eqv = $lcm->is_LequivalentR(2) };
like($@,
    qr/Method List::Compare::Multiple::is_LequivalentR requires 2 arguments/,
    "Got expected error message",
);

eval { $eqv = $lcm->is_LequivalentR(8,9) };
like($@,
    qr/Each argument to method List::Compare::Multiple::is_LequivalentR must be a valid array index/,
    "Got expected error message",
);

{
    my ($rv, $stdout, $stderr);
    capture(
        sub { $rv = $lcm->print_subset_chart; },
        \$stdout,
    );
    ok($rv, "print_subset_chart() returned true value");
    like($stdout, qr/Subset Relationships/,
        "Got expected chart header");
}
{
    my ($rv, $stdout, $stderr);
    capture(
        sub { $rv = $lcm->print_equivalence_chart; },
        \$stdout,
    );
    ok($rv, "print_equivalence_chart() returned true value");
    like($stdout, qr/Equivalence Relationships/,
        "Got expected chart header");
}

@args = qw( abel baker camera delta edward fargo golfer hilton icon jerky zebra );
is_deeply( all_is_member_which( $lcm, \@args), $test_member_which_mult,
    "is_member_which() returned all expected values");

eval { $memb_arr_ref = $lcm->is_member_which('jerky', 'zebra') };
like($@, qr/Method call requires exactly 1 argument \(no references\)/,
        "is_member_which() correctly generated error message");

is_deeply( all_is_member_which_ref( $lcm, \@args), $test_member_which_mult,
    "is_member_which_ref() returned all expected values");

eval { $memb_arr_ref = $lcm->is_member_which_ref('jerky', 'zebra') };
like($@, qr/Method call requires exactly 1 argument \(no references\)/,
        "is_member_which_ref() correctly generated error message");

$memb_hash_ref = $lcm->are_members_which( \@args );
is_deeply($memb_hash_ref, $test_members_which_mult,
   "are_members_which() returned all expected values");

eval { $memb_hash_ref = $lcm->are_members_which( { key => 'value' } ) };
like($@,
    qr/Method call requires exactly 1 argument which must be an array reference/,
    "are_members_which() correctly generated error message");

is_deeply( all_is_member_any( $lcm, \@args), $test_member_any_mult,
    "is_member_which() returned all expected values");

eval { $lcm->is_member_any('jerky', 'zebra') };
like($@,
    qr/Method call requires exactly 1 argument \(no references\)/,
    "is_member_any() correctly generated error message");

$memb_hash_ref = $lcm->are_members_any( \@args );
ok(wrap_are_members_any(
    $memb_hash_ref,
    $test_members_any_mult,
), "are_members_any() returned all expected values");

eval { $memb_hash_ref = $lcm->are_members_any( { key => 'value' } ) };
like($@,
    qr/Method call requires exactly 1 argument which must be an array reference/,
    "are_members_any() correctly generated error message");

$vers = $lcm->get_version;
ok($vers, "get_version() returned true value");

### new ###
my $lcm_dj   = List::Compare->new(\%h0, \%h1, \%h2, \%h3, \%h4, \%h8);
ok($lcm_dj, "Constructor returned true value");

$disj = $lcm_dj->is_LdisjointR;
ok(! $disj, "Got expected disjoint relationship");

$disj = $lcm_dj->is_LdisjointR(2,3);
ok(! $disj, "Got expected disjoint relationship");

$disj = $lcm_dj->is_LdisjointR(4,5);
ok($disj, "Got expected disjoint relationship");

eval { $disj = $lcm_dj->is_LdisjointR(2) };
like($@, qr/Method List::Compare::Multiple::is_LdisjointR requires 2 arguments/,
    "Got expected error message");

########## BELOW:  Testfor bad arguments to constructor ##########

my ($lcm_bad);

my $scalar = 'test';
eval { $lcm_bad = List::Compare->new(\$scalar, \%h0, \%h1) };
like($@, qr/Must pass all array references or all hash references/,
    "Got expected error message from bad constructor");
