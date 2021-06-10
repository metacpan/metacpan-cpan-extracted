# Test of asynchronous hash access courtesy of Tim Fries <timf@dicecorp.com>

use warnings;
use strict;

use Carp;
use IPC::Shareable;
use Test::More;

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

    tie my %thash, 'IPC::Shareable', 'hobj', { destroy => 0 };

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

    tie my %thash, 'IPC::Shareable', 'hobj', { create => 'yes' };

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

done_testing();
