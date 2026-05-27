use strict;
use warnings;

use Data::Dumper;
use Test::More;
use IPC::Shareable;
IPC::Shareable->testing_set('IPC::Shareable');

my $segs_before = IPC::Shareable::seg_count();
my $sems_before = IPC::Shareable::sem_count();
warn "Segs Before: $segs_before\n" if $ENV{PRINT_SEGS};

my $mod = 'IPC::Shareable';

# serializer: storable
{
    my $knot = tie my %hv, $mod, {
        create     => 1,
        key        => 1234,
        destroy    => 1,
        # serializer => 'json',
        #    persist => 1
    };

    my %check;
    my (@k, @v, %used);

    for (0 .. 9) {
        my $n;

        do {
            $n = int(rand(26));
        } while (exists $used{$n});

        $used{$n} ++;

        push @k, ('a' .. 'z')[$n];
        push @v, ('A' .. 'Z')[$n];
    }
    @check{@k} = @v;

    while (my ($k, $v) = each %check) {
        $hv{$k} = $v;
    }

    is keys(%hv), 10, "hv has proper number of keys";

    while (my ($k, $v) = each %check) {
        is $hv{$k}, $v, "check hash $k matches hv val $v";
    }

    # --- EXISTS

    $hv{there} = undef;
    is exists($hv{there}), 1, "exists() works ok";
    is defined($hv{there}), '', "defined with undef val ok";

    # --- DELETE
    $hv{there}->{here} = 'yes';
    is $hv{there}->{here}, 'yes', "hv there is ok";
    $hv{there}->{here} = 'no';
    is $hv{there}->{here}, 'no', "hv there is ok again";

    $hv{there} = 'yes';
    is $hv{there}, 'yes', "hv there is ok";
    is defined($hv{there}), 1, "defined with val ok";
    $hv{there} = 'no';
    is $hv{there}, 'no', "hv there is ok again";
    delete $hv{there};

    is exists($hv{there}), '', "delete removes hash key and value";

    # --- DELETE a key whose value is a nested tied child segment
    # Exercises the $child->remove path in DELETE
    $hv{nested} = { inner => 42 };
    is ref($hv{nested}), 'HASH', "nested child segment created ok";
    is $hv{nested}{inner}, 42,   "nested child segment value ok";

    my $child_segs_before = IPC::Shareable::seg_count();
    delete $hv{nested};
    my $child_segs_after = IPC::Shareable::seg_count();
    is exists($hv{nested}), '', "delete of child-segment key removes it ok";
    is $child_segs_after, $child_segs_before - 1, "DELETE child: child segment removed from system ok";

    # --- CLEAR a hash that contains a nested tied child segment
    # Exercises the $child->remove path in CLEAR
    $hv{keep}   = 'plain';
    $hv{nested} = { inner => 99 };
    is $hv{nested}{inner}, 99, "nested child for CLEAR test set ok";

    my $clear_segs_before = IPC::Shareable::seg_count();
    %hv = ();
    my $clear_segs_after = IPC::Shareable::seg_count();
    is keys(%hv), 0, "clearing a hash with child segments works ok";
    is $clear_segs_after, $clear_segs_before - 1, "CLEAR: child segment removed from system ok";

    IPC::Shareable->clean_up_all;

    is % hv, '', "hash deleted after clean_up()";
}

# serializer: json
{
    my $knot = tie my %hv, $mod, {
        create     => 1,
        key        => 1234,
        destroy    => 1,
        serializer => 'json',
        #    persist => 1
    };

    my %check;
    my (@k, @v, %used);

    for (0 .. 9) {
        my $n;

        do {
            $n = int(rand(26));
        } while (exists $used{$n});

        $used{$n} ++;

        push @k, ('a' .. 'z')[$n];
        push @v, ('A' .. 'Z')[$n];
    }
    @check{@k} = @v;

    while (my ($k, $v) = each %check) {
        $hv{$k} = $v;
    }

    is keys(%hv), 10, "json: hv has proper number of keys";

    while (my ($k, $v) = each %check) {
        is $hv{$k}, $v, "json: check hash $k matches hv val $v";
    }

    # --- EXISTS

    $hv{there} = undef;
    is exists($hv{there}), 1, "json: exists() works ok";
    is defined($hv{there}), '', "json: defined with undef val ok";

    # --- DELETE
    $hv{there}->{here} = 'yes';
    is $hv{there}->{here}, 'yes', "json: hv there is ok";
    $hv{there}->{here} = 'no';
    is $hv{there}->{here}, 'no', "json: hv there is ok again";

    $hv{there} = 'yes';
    is $hv{there}, 'yes', "json: hv there is ok";
    is defined($hv{there}), 1, "json: defined with val ok";
    $hv{there} = 'no';
    is $hv{there}, 'no', "json: hv there is ok again";
    delete $hv{there};

    is exists($hv{there}), '', "json: delete removes hash key and value";

    # --- DELETE a key whose value is a nested tied child segment
    $hv{nested} = { inner => 42 };
    is ref($hv{nested}), 'HASH', "json: nested child segment created ok";
    is $hv{nested}{inner}, 42,   "json: nested child segment value ok";

    my $child_segs_before = IPC::Shareable::seg_count();
    delete $hv{nested};
    my $child_segs_after = IPC::Shareable::seg_count();
    is exists($hv{nested}), '', "json: delete of child-segment key removes it ok";
    is $child_segs_after, $child_segs_before - 1, "json: DELETE child: child segment removed from system ok";

    # --- CLEAR a hash that contains nested tied child segments
    $hv{keep}   = 'plain';
    $hv{nested} = { inner => 99 };
    is $hv{nested}{inner}, 99, "json: nested child for CLEAR test set ok";

    my $clear_segs_before = IPC::Shareable::seg_count();
    %hv = ();
    my $clear_segs_after = IPC::Shareable::seg_count();
    is keys(%hv), 0, "json: clearing a hash with child segments works ok";
    is $clear_segs_after, $clear_segs_before - 1, "json: CLEAR: child segment removed from system ok";

    IPC::Shareable->clean_up_all;

    is % hv, '', "hash deleted after clean_up()";
}

IPC::Shareable::_end;

my $segs_after = IPC::Shareable::seg_count();
warn "Segs After: $segs_after\n" if $ENV{PRINT_SEGS};
is $segs_after, $segs_before, "All segs cleaned up ok";
my $sems_after = IPC::Shareable::sem_count();
is $sems_after, $sems_before, "All semaphore sets cleaned up ok";

done_testing();


