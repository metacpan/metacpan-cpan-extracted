use warnings;
use strict;

use Carp;
use IPC::Shareable;
use Test::More;

my $segs_before = IPC::Shareable::seg_count();
my $sems_before = IPC::Shareable::sem_count();
warn "Segs Before: $segs_before\n" if $ENV{PRINT_SEGS};

my $t  = 1;
my $ok = 1;

my $awake = 0;
local $SIG{ALRM} = sub { $awake = 1 };

my $pid = fork;
defined $pid or die "Cannot fork: $!";

if ($pid == 0) {
    sleep unless $awake;
    $awake = 0;

    my @av;

    my $ipch = tie @av, 'IPC::Shareable', "foco", {
        create    => 1,
        exclusive => 0,
        mode      => 0666,
        size      => 1024*512,
        destroy   => 0,
            serializer => 'storable',
    };

    @av = ();

    for (my $i = 1; $i <= 10; $i++) {
        $ipch->shlock;
        push(@av, $i);
        $ipch->shunlock;
    }

    sleep unless $awake;
    @av and undef $ok;
    exit;

} else {
    my @av;
    my $ipch = tie @av, 'IPC::Shareable', "foco", {
        create    => 1,
        exclusive => 0,
        mode      => 0666,
        size      => 1024*512,
        destroy   => 'yes',
            serializer => 'storable',
    };
    @av = ();
    kill ALRM => $pid;
    
    my %seen;
    sleep 1 until @av;

    while (@av) {
        $ipch->shlock;
        my $line = shift @av;
        ++$seen{$line};
        $ipch->shunlock;
    }
    kill ALRM => $pid;
    waitpid($pid, 0);

    my $count = 0;
    for (1..10){
        is $seen{$_}, 1, "child set elem $count to $_ ok";
        $count++;
    }
    IPC::Shareable->clean_up_all;
}

IPC::Shareable::_end;

my $segs_after = IPC::Shareable::seg_count();
warn "Segs After: $segs_after\n" if $ENV{PRINT_SEGS};
is $segs_after, $segs_before, "All segs cleaned up ok";
my $sems_after = IPC::Shareable::sem_count();
is $sems_after, $sems_before, "All semaphore sets cleaned up ok";

done_testing();
