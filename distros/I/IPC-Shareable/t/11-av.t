use warnings;
use strict;

use IPC::Shareable;
IPC::Shareable->testing_set('IPC::Shareable');
use Test::More;

my $mod = 'IPC::Shareable';

my $segs_before = IPC::Shareable::seg_count();
my $sems_before = IPC::Shareable::sem_count();
warn "Segs Before: $segs_before\n" if $ENV{PRINT_SEGS};

# serializer: storable
{
    tie my @av, $mod, { key => 'av11', create => 1, destroy => 1 };

    my @words = qw(tic tac toe);
    @av = qw(tic tac toe);

    for (0 .. 2) {
        is $av[$_], $words[$_], "storable: shared array populated ok: $_";
    }

    $#av = 5;
    is scalar(@av), 6, "storable: array count ok";

    for (3 .. 5) {
        is defined $av[$_], '', "storable: array elem $_ is present but undefined";
    }

    is $#av, 5, "storable: array len ok";

    @av = ();
    is scalar(@av), 0, "storable: shared array cleared ok";

    @av = qw(fee fie foe fum);

    my $fum = pop @av;
    is $fum, 'fum', "storable: pop ok";
    is $#av, 2, "storable: after pop, proper element count ok";

    push @av => $fum;
    is $av[3], $fum, "storable: push ok";
    is $#av, 3, "storable: push adds element ok";

    my $fee = shift @av;
    is $fee, 'fee', "storable: shift ok";
    is $#av, 2, "storable: after shift, proper element count ok";

    unshift @av => $fee;
    is $fee, 'fee', "storable: unshift ok";
    is $#av, 3, "storable: after unshift, proper element count ok";

    my (@gone) = splice @av, 1, 2, qw(i spliced);
    is $av[1], 'i',       "storable: splice 1 ok";
    is $av[2], 'spliced', "storable: splice 2 ok";
    is $gone[0], 'fie',   "storable: splice 3 ok";
    is $gone[1], 'foe',   "storable: splice 4 ok";

    # --- nested structures

    @av = ();

    # arrayref element
    $av[0] = [10, 20, 30];
    is ref($av[0]), 'ARRAY', "storable: nested arrayref element ok";
    is $av[0][1], 20, "storable: nested arrayref element value ok";

    # hashref element
    $av[1] = { name => 'perl', version => 5 };
    is ref($av[1]), 'HASH', "storable: nested hashref element ok";
    is $av[1]{name}, 'perl', "storable: nested hashref element value ok";

    # deeper nesting: hashref containing arrayref
    $av[2] = { list => [1, 2, 3], meta => { ok => 1 } };
    is ref($av[2]{list}), 'ARRAY',  "storable: deep nested arrayref ok";
    is $av[2]{list}[2], 3,          "storable: deep nested arrayref value ok";
    is $av[2]{meta}{ok}, 1,         "storable: deep nested hashref value ok";

    # array of arrayrefs
    $av[3] = [[qw(a b)], [qw(c d)]];
    is $av[3][0][1], 'b', "storable: array of arrayrefs ok";
    is $av[3][1][0], 'c', "storable: array of arrayrefs second element ok";

    IPC::Shareable->clean_up_all;
}

# serializer: json
{
    tie my @av, $mod, { key => 'av11', create => 1, destroy => 1, serializer => 'json' };

    my @words = qw(tic tac toe);
    @av = qw(tic tac toe);

    for (0 .. 2) {
        is $av[$_], $words[$_], "json: shared array populated ok: $_";
    }

    $#av = 5;
    is scalar(@av), 6, "json: array count ok";

    for (3 .. 5) {
        is defined $av[$_], '', "json: array elem $_ is present but undefined";
    }

    is $#av, 5, "json: array len ok";

    @av = ();
    is scalar(@av), 0, "json: shared array cleared ok";

    @av = qw(fee fie foe fum);

    my $fum = pop @av;
    is $fum, 'fum', "json: pop ok";
    is $#av, 2, "json: after pop, proper element count ok";

    push @av => $fum;
    is $av[3], $fum, "json: push ok";
    is $#av, 3, "json: push adds element ok";

    my $fee = shift @av;
    is $fee, 'fee', "json: shift ok";
    is $#av, 2, "json: after shift, proper element count ok";

    unshift @av => $fee;
    is $fee, 'fee', "json: unshift ok";
    is $#av, 3, "json: after unshift, proper element count ok";

    my (@gone) = splice @av, 1, 2, qw(i spliced);
    is $av[1], 'i',       "json: splice 1 ok";
    is $av[2], 'spliced', "json: splice 2 ok";
    is $gone[0], 'fie',   "json: splice 3 ok";
    is $gone[1], 'foe',   "json: splice 4 ok";

    # --- nested structures

    @av = ();

    # arrayref element
    $av[0] = [10, 20, 30];
    is ref($av[0]), 'ARRAY', "json: nested arrayref element ok";
    is $av[0][1], 20, "json: nested arrayref element value ok";

    # hashref element
    $av[1] = { name => 'perl', version => 5 };
    is ref($av[1]), 'HASH', "json: nested hashref element ok";
    is $av[1]{name}, 'perl', "json: nested hashref element value ok";

    # deeper nesting: hashref containing arrayref
    $av[2] = { list => [1, 2, 3], meta => { ok => 1 } };
    is ref($av[2]{list}), 'ARRAY',  "json: deep nested arrayref ok";
    is $av[2]{list}[2], 3,          "json: deep nested arrayref value ok";
    is $av[2]{meta}{ok}, 1,         "json: deep nested hashref value ok";

    # array of arrayrefs
    $av[3] = [[qw(a b)], [qw(c d)]];
    is $av[3][0][1], 'b', "json: array of arrayrefs ok";
    is $av[3][1][0], 'c', "json: array of arrayrefs second element ok";

    IPC::Shareable->clean_up_all;
}

# FETCH from a never-written array segment returns undef (empty segment path)
{
    tie my @av, $mod, { key => 'av11e', create => 1, destroy => 1 };
    is $av[0], undef, "FETCH on never-written array element returns undef ok";
}

IPC::Shareable::_end;

my $segs_after = IPC::Shareable::seg_count();
warn "Segs After: $segs_after\n" if $ENV{PRINT_SEGS};
is $segs_after, $segs_before, "All segs cleaned up ok";
my $sems_after = IPC::Shareable::sem_count();
is $sems_after, $sems_before, "All semaphore sets cleaned up ok";

done_testing();
