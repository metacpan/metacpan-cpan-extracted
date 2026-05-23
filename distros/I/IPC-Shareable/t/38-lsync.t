# Test of asynchronous hash access courtesy of Tim Fries <timf@dicecorp.com>

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

my $ppid = $$;
my $pid = fork;
defined $pid or die "Cannot fork : $!";

if ($pid == 0) {
    # child

    sleep unless $awake;
    $awake = 0;

    tie my %thash, 'IPC::Shareable', 'hobj', { destroy => 0 , serializer => 'storable' };

    $thash{'foo'} = "marlinspike";
    $thash{'bar'} = "ballyhoo";
    $thash{'quux'} = "calvinball";

    kill ALRM => $ppid;
    sleep unless $awake;

#    is defined $thash{'foo'}, 1, "child: thash foo defined";
#    is $thash{'foo'}, 'marlinspike', "child: thash foo val is good";
#
#    is defined $thash{'bar'}, 1, "child: thash bar defined";
#    is $thash{'bar'}, 'ballyhoo', "child: thash bar val is good";
#
#    is defined $thash{'quux'}, 1, "child: thash quux defined";
#    is $thash{'quux'}, 'calvinball', "child: thash quux val is good";

    exit;

} else {
    # parent

    my $awake = 0;
    local $SIG{ALRM} = sub { $awake = 1 };

    tie my %thash, 'IPC::Shareable', 'hobj', { create => 'yes' , serializer => 'storable' };

    kill ALRM => $pid;
    sleep unless $awake;
 
    $thash{'intel'} = "expensive";
    $thash{'amd'} = "volthungry";
    $thash{'cyrix'} = "mia";
   
    kill ALRM => $pid;
    waitpid($pid, 0);

    is defined $thash{'foo'}, 1, "parent: thash foo defined";
    is $thash{'foo'}, 'marlinspike', "parent: thash foo val is good";

    is defined $thash{'bar'}, 1, "parent: thash bar defined";
    is $thash{'bar'}, 'ballyhoo', "parent: thash bar val is good";

    is defined $thash{'quux'}, 1, "parent: thash quux defined";
    is $thash{'quux'}, 'calvinball', "parent: thash quux val is good";

    IPC::Shareable->clean_up_all;

    is %thash, '', "data cleaned up after clean_up_all()";
}

IPC::Shareable::_end;

my $segs_after = IPC::Shareable::seg_count();
warn "Segs After: $segs_after\n" if $ENV{PRINT_SEGS};
is $segs_after, $segs_before, "All segs cleaned up ok";
my $sems_after = IPC::Shareable::sem_count();
is $sems_after, $sems_before, "All semaphore sets cleaned up ok";

done_testing();
