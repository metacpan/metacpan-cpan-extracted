use warnings;
use strict;

use Data::Dumper;
use IPC::Shareable;
use Test::More;
use Test::SharedFork;

BEGIN {
    if (! $ENV{CI_TESTING}) {
        plan skip_all => "Not on a legit CI platform...";
    }
}

warn "Segs Before: " . IPC::Shareable::ipcs() . "\n" if $ENV{PRINT_SEGS};

my $mod = 'IPC::Shareable';

my $awake = 0;
local $SIG{ALRM} = sub { $awake = 1 };

# locking

my $pid = fork;
defined $pid or die "Cannot fork: $!\n";

if ($pid == 0) {
    # child

    sleep unless $awake;

    my $ch = $mod->new(key => 'hash2');
    $ch->{child} = 'child';

    my $ca = $mod->new(key => 'array2', var => 'ARRAY');
    $ca->[1] = 'child';

    my $cs = $mod->new(key => 'scalar2', var => 'SCALAR');
    $$cs = 'child';

} else {
    # parent

    my $ph = $mod->new(key => 'hash2', create => 1, destroy => 1);
    like tied(%$ph), qr/IPC::Shareable/, "new() tied hash is proper object ok";
    like tied(%$ph)->can('ipcs'), qr/CODE/, "...and it can call its methods ok";

    my $pa = $mod->new(key => 'array2', create => 1, destroy => 1, var => 'ARRAY');
    like tied(@$pa), qr/IPC::Shareable/, "new() tied array is proper object ok";
    like tied(@$pa)->can('ipcs'), qr/CODE/, "...and it can call its methods ok";

    my $ps = $mod->new(key => 'scalar2', create => 1, destroy => 1, var => 'SCALAR');
    like tied($$ps), qr/IPC::Shareable/, "new() tied scalar is proper object ok";
    like tied($$ps)->can('ipcs'), qr/CODE/, "...and it can call its methods ok";

    kill ALRM => $pid;
    waitpid($pid, 0);

    is $ph->{child}, 'child', 'child set the hash value ok';
    is $pa->[1], 'child', 'child set the array value ok';
    is $$ps, 'child', 'child set the scalar value ok';

    $ph->{parent} = 'parent';
    is $ph->{parent}, 'parent', 'parent set the hash value ok';

    $pa->[0] = 'parent';
    is $pa->[0], 'parent', 'parent set the array value ok';

    $$ps = "parent";
    is $$ps, 'parent', 'parent set the scalar value ok';

    IPC::Shareable->clean_up_all;

    warn "Segs After: " . IPC::Shareable::ipcs() . "\n" if $ENV{PRINT_SEGS};

    done_testing();
}

