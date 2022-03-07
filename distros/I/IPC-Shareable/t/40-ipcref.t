use warnings;
use strict;

use Carp;
use IPC::Shareable;
use Test::More;
use Test::SharedFork;

BEGIN {
    if (! $ENV{CI_TESTING}) {
        plan skip_all => "Not on a legit CI platform...";
    }
}

my $t  = 1;
my $ok = 1;

my $awake = 0;
local $SIG{ALRM} = sub { $awake = 1 };

my($av, $hv);

my $pid = fork;
defined $pid or die "Cannot fork : $!";

if ($pid == 0) {
    # child

    sleep unless $awake;

    tie $hv, 'IPC::Shareable', 'hash1', { destroy => 0 };
    tie $av, 'IPC::Shareable', 'arry1', { destroy => 0 };

    is $hv, 'baz', "child: HV is 'baz' ok";
    is $av, 'bong', "child: AV is 'bong' ok";

    $hv = { };
    $av = [ ];

    $av->[1]->[2] = 'beep';
    $av->[2]->[3] = 'bang';

    is $av->[1]->[2], 'beep', "child: nested AV 1 has 'beep' ok";
    is $av->[2]->[3], 'bang', "child: nested AV 2 has 'bang' ok";

    $hv->{blip}->{blarp} = 'blurp';
    $hv->{flip}->{flop}  = 'flurp';

    is $hv->{blip}->{blarp}, 'blurp', "child: nested HV 1 is 'blurp' ok";
    is $hv->{flip}->{flop}, 'flurp', "child: nested HV 2 is 'flurp' ok";


    exit;
} else {
    # parent

    tie $hv, 'IPC::Shareable', 'hash1', { create => 1, destroy => 1 };
    tie $av, 'IPC::Shareable', 'arry1', { create => 1, destroy => 1 };

    $hv = 'baz';
    $av = 'bong';

    kill ALRM => $pid;
    waitpid($pid, 0);

    is $hv->{blip}->{blarp}, 'blurp', "parent: nested HV 1 is 'blurp' ok";
    is $hv->{flip}->{flop}, 'flurp', "parent: nested HV 2 is 'flurp' ok";

    is $av->[1]->[2], 'beep', "parent: nested AV 1 has 'beep' ok";
    is $av->[2]->[3], 'bang', "parent: nested AV 2 has 'bang' ok";

    IPC::Shareable->clean_up_all;

    is defined $av, '', "AV cleaned after clean_up_all()";
    is defined $hv, '', "HV cleaned after clean_up_all()";
}

done_testing();
