use warnings;
use strict;

use Carp;
use IPC::Shareable;
use Test::More;
use Test::SharedFork;

my $segs_before = IPC::Shareable::seg_count();
my $sems_before = IPC::Shareable::sem_count();
warn "Segs Before: $segs_before\n" if $ENV{PRINT_SEGS};

# serializer: storable
{
    my $awake = 0;
    local $SIG{ALRM} = sub { $awake = 1 };

    my($av, $hv);

    my $pid = fork;
    defined $pid or die "Cannot fork : $!";

    if ($pid == 0) {
        # child

        sleep unless $awake;

        tie $hv, 'IPC::Shareable', 'hash1', { destroy => 0 , serializer => 'storable' };
        tie $av, 'IPC::Shareable', 'arry1', { destroy => 0 , serializer => 'storable' };

        is $hv, 'baz', "storable: child: HV is 'baz' ok";
        is $av, 'bong', "storable: child: AV is 'bong' ok";

        $hv = { };
        $av = [ ];

        $av->[1]->[2] = 'beep';
        $av->[2]->[3] = 'bang';

        is $av->[1]->[2], 'beep', "storable: child: nested AV 1 has 'beep' ok";
        is $av->[2]->[3], 'bang', "storable: child: nested AV 2 has 'bang' ok";

        $hv->{blip}->{blarp} = 'blurp';
        $hv->{flip}->{flop}  = 'flurp';

        is $hv->{blip}->{blarp}, 'blurp', "storable: child: nested HV 1 is 'blurp' ok";
        is $hv->{flip}->{flop}, 'flurp', "storable: child: nested HV 2 is 'flurp' ok";

        exit;
    } else {
        # parent

        tie $hv, 'IPC::Shareable', 'hash1', { create => 1, destroy => 1 , serializer => 'storable' };
        tie $av, 'IPC::Shareable', 'arry1', { create => 1, destroy => 1 , serializer => 'storable' };

        $hv = 'baz';
        $av = 'bong';

        kill ALRM => $pid;
        waitpid($pid, 0);

        is $hv->{blip}->{blarp}, 'blurp', "storable: parent: nested HV 1 is 'blurp' ok";
        is $hv->{flip}->{flop}, 'flurp', "storable: parent: nested HV 2 is 'flurp' ok";

        is $av->[1]->[2], 'beep', "storable: parent: nested AV 1 has 'beep' ok";
        is $av->[2]->[3], 'bang', "storable: parent: nested AV 2 has 'bang' ok";

        IPC::Shareable->clean_up_all;

        is defined $av, '', "storable: AV cleaned after clean_up_all()";
        is defined $hv, '', "storable: HV cleaned after clean_up_all()";
    }
}

# serializer: json
{
    my $awake = 0;
    local $SIG{ALRM} = sub { $awake = 1 };

    my($av, $hv);

    my $pid = fork;
    defined $pid or die "Cannot fork : $!";

    if ($pid == 0) {
        # child

        sleep unless $awake;

        tie $hv, 'IPC::Shareable', 'hash1j', { destroy => 0, serializer => 'json' };
        tie $av, 'IPC::Shareable', 'arry1j', { destroy => 0, serializer => 'json' };

        is $hv, 'baz', "json: child: HV is 'baz' ok";
        is $av, 'bong', "json: child: AV is 'bong' ok";

        $hv = { };
        $av = [ ];

        $av->[1]->[2] = 'beep';
        $av->[2]->[3] = 'bang';

        is $av->[1]->[2], 'beep', "json: child: nested AV 1 has 'beep' ok";
        is $av->[2]->[3], 'bang', "json: child: nested AV 2 has 'bang' ok";

        $hv->{blip}->{blarp} = 'blurp';
        $hv->{flip}->{flop}  = 'flurp';

        is $hv->{blip}->{blarp}, 'blurp', "json: child: nested HV 1 is 'blurp' ok";
        is $hv->{flip}->{flop}, 'flurp', "json: child: nested HV 2 is 'flurp' ok";

        exit;
    } else {
        # parent

        tie $hv, 'IPC::Shareable', 'hash1j', { create => 1, destroy => 1, serializer => 'json' };
        tie $av, 'IPC::Shareable', 'arry1j', { create => 1, destroy => 1, serializer => 'json' };

        $hv = 'baz';
        $av = 'bong';

        kill ALRM => $pid;
        waitpid($pid, 0);

        is $hv->{blip}->{blarp}, 'blurp', "json: parent: nested HV 1 is 'blurp' ok";
        is $hv->{flip}->{flop}, 'flurp', "json: parent: nested HV 2 is 'flurp' ok";

        is $av->[1]->[2], 'beep', "json: parent: nested AV 1 has 'beep' ok";
        is $av->[2]->[3], 'bang', "json: parent: nested AV 2 has 'bang' ok";

        IPC::Shareable->clean_up_all;

        is defined $av, '', "json: AV cleaned after clean_up_all()";
        is defined $hv, '', "json: HV cleaned after clean_up_all()";
    }
}

IPC::Shareable::_end;

my $segs_after = IPC::Shareable::seg_count();
warn "Segs After: $segs_after\n" if $ENV{PRINT_SEGS};
is $segs_after, $segs_before, "All segs cleaned up ok";
my $sems_after = IPC::Shareable::sem_count();
is $sems_after, $sems_before, "All semaphore sets cleaned up ok";

done_testing();
