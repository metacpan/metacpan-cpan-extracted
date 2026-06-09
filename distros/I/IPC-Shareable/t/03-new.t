use warnings;
use strict;

use Data::Dumper;
use IPC::Shareable;
IPC::Shareable->testing_set('IPC::Shareable');
use Test::More;

use FindBin;
use lib $FindBin::Bin;
use IPCShareableTest qw(
    assert_clean_process barrier_new barrier_release barrier_wait unique_glue
);
use Test::SharedFork;


my $mod = 'IPC::Shareable';

# A pipe barrier (see IPCShareableTest::barrier_new) replaces the old
# SIGALRM/sleep handshake and its lost-wakeup race.

my $ready = barrier_new();   # parent -> child: segments created

# locking

my $pid = fork;
defined $pid or die "Cannot fork: $!\n";

if ($pid == 0) {
    # child

    barrier_wait($ready);

    my $ch = $mod->new(key => unique_glue('hash2'));
    $ch->{child} = 'child';

    my $ca = $mod->new(key => unique_glue('array2'), var => 'ARRAY');
    $ca->[1] = 'child';

    my $cs = $mod->new(key => unique_glue('scalar2'), var => 'SCALAR');
    $$cs = 'child';

} else {
    # parent

    my $ph = $mod->new(key => unique_glue('hash2'), create => 1, destroy => 1);
    like tied(%$ph), qr/IPC::Shareable/, "new() tied hash is proper object ok";
    like tied(%$ph)->can('seg_count'), qr/CODE/, "...and it can call its methods ok";

    my $pa = $mod->new(key => unique_glue('array2'), create => 1, destroy => 1, var => 'ARRAY');
    like tied(@$pa), qr/IPC::Shareable/, "new() tied array is proper object ok";
    like tied(@$pa)->can('seg_count'), qr/CODE/, "...and it can call its methods ok";

    my $ps = $mod->new(key => unique_glue('scalar2'), create => 1, destroy => 1, var => 'SCALAR');
    like tied($$ps), qr/IPC::Shareable/, "new() tied scalar is proper object ok";
    like tied($$ps)->can('seg_count'), qr/CODE/, "...and it can call its methods ok";

    barrier_release($ready);
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

    assert_clean_process();

    done_testing();
}

