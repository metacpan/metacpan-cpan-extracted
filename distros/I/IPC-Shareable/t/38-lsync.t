# Test of asynchronous hash access courtesy of Tim Fries <timf@dicecorp.com>

use warnings;
use strict;

use Carp;
use IPC::Shareable;
IPC::Shareable->testing_set('IPC::Shareable');
use Test::More;

use FindBin;
use lib $FindBin::Bin;
use IPCShareableTest qw(assert_clean_process unique_glue);

# A two-pipe handshake replaces the old SIGALRM/sleep handshake, which had a
# lost-wakeup race: a signal delivered in the window after the "unless $awake"
# check but before sleep() blocked the process forever (it deadlocked under
# emulation). Each writer closes its pipe end right after the single write, so
# the read unblocks (flush + EOF) and cannot miss the wakeup. Same idiom as
# t/26, t/19, and t/24.

my $glue = unique_glue('hobj');

pipe(my $ready_r, my $ready_w) or die "Cannot create pipe: $!";  # parent -> child
pipe(my $done_r,  my $done_w)  or die "Cannot create pipe: $!";  # child  -> parent

my $pid = fork;
defined $pid or die "Cannot fork: $!";

if ($pid == 0) {
    # child: attach once the parent has created the segment, write three keys,
    # tell the parent, then exit
    close $ready_w;
    close $done_r;

    <$ready_r>;          # wait: parent has created the segment
    close $ready_r;

    tie my %thash, 'IPC::Shareable', $glue, { destroy => 0, serializer => 'storable' };

    $thash{'foo'}  = "marlinspike";
    $thash{'bar'}  = "ballyhoo";
    $thash{'quux'} = "calvinball";

    print $done_w "done\n";   # tell parent: keys written
    close $done_w;

    exit;
}

# parent
close $ready_r;
close $done_w;

tie my %thash, 'IPC::Shareable', $glue, { create => 'yes', serializer => 'storable' };

print $ready_w "go\n";   # segment exists; child may attach and write
close $ready_w;

<$done_r>;               # block until the child has written its keys
close $done_r;

$thash{'intel'} = "expensive";
$thash{'amd'}   = "volthungry";
$thash{'cyrix'} = "mia";

waitpid($pid, 0);

is defined $thash{'foo'}, 1, "parent: thash foo defined";
is $thash{'foo'}, 'marlinspike', "parent: thash foo val is good";

is defined $thash{'bar'}, 1, "parent: thash bar defined";
is $thash{'bar'}, 'ballyhoo', "parent: thash bar val is good";

is defined $thash{'quux'}, 1, "parent: thash quux defined";
is $thash{'quux'}, 'calvinball', "parent: thash quux val is good";

IPC::Shareable->clean_up_all;

is %thash, '', "data cleaned up after clean_up_all()";

IPC::Shareable::_end;

assert_clean_process();

done_testing();
