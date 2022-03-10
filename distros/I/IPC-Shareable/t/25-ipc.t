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

warn "Segs Before: " . IPC::Shareable::ipcs() . "\n" if $ENV{PRINT_SEGS};

my $awake = 0;
local $SIG{ALRM} = sub { $awake = 1 };

my $pid = fork;
defined $pid or die "Cannot fork: $!";

if ($pid == 0) {
    # child

    sleep unless $awake;

    tie my %h, 'IPC::Shareable', { key => 'testing25', destroy => 0 };
    $h{a} = 'foo';
    exit;
} else {
    # parent

    tie my %h, 'IPC::Shareable', {
        key     => 'testing25',
        create  => 1,
        destroy => 1,
    };

    $h{a} = 'bar';
    is $h{a}, 'bar', "in parent: parent set HV to 'bar' ok";

    kill ALRM => $pid;
    waitpid($pid, 0);

    is $h{a}, 'foo', "in parent: child set HV to 'foo' ok";

    IPC::Shareable->clean_up_all;
}

IPC::Shareable::_end;
warn "Segs After: " . IPC::Shareable::ipcs() . "\n" if $ENV{PRINT_SEGS};

done_testing();
