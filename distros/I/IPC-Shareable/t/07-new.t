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
    my $pa = $mod->new(key => 'array2', create => 1, destroy => 1, var => 'ARRAY');
    my $ps = $mod->new(key => 'scalar2', create => 1, destroy => 1, var => 'SCALAR');

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

    done_testing();
}

