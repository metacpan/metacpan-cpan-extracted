use warnings;
use strict;

use Carp;
use IPC::Shareable;
use Test::More;

BEGIN {
    if (! $ENV{CI_TESTING}) {
        plan skip_all => "Not on a legit CI platform...";
    }
}

warn "Segs Before: " . IPC::Shareable::ipcs() . "\n" if $ENV{PRINT_SEGS};

plan tests => 8;

my %shareOpts = (
		 create =>       'yes',
		 exclusive =>    0,
		 mode =>         0644,
		 destroy =>      'yes',
		 );

my $awake = 0;
local $SIG{ALRM} = sub { $awake = 1 };

my $pid = fork;
defined $pid or die "Cannot fork: $!";

if ($pid == 0) {
    # child

    sleep unless $awake;
    $awake = 0;

    my $ipch = tie my %hv, 'IPC::Shareable', "test", {
        create    => 'yes',
        exclusive => 0,
        mode      => 0644,
        destroy   => 0,
    };

    for (qw(fee fie foe fum)) {
        $ipch->shlock();
        $hv{$_} = $$;
        $ipch->shunlock();
    }

    sleep unless $awake;

#    for (qw(fee fie foe fum)) {
#        is $hv{$_}, $$, "child: HV key $_ has val $$";
#    }

    my $parent = getppid;
    $parent == 1 and die "Parent process has unexpectedly gone away";

#    for (qw(eenie meenie minie moe)) {
#        is $hv{$_}, $parent, "child: HV key $_ has val $parent (parent PID)";
#    }
} else {
    # parent

    my $ipch = tie my %hv, 'IPC::Shareable', "test", {
        create    => 1,
        exclusive => 0,
        mode      => 0666,
        size      => 1024*512,
        destroy   => 'yes',
    };

    %hv = ();

    kill ALRM => $pid;
    sleep 1;           # Allow time for child to process the signal before next ALRM comes in
    
    for (qw(eenie meenie minie moe)) {
        $ipch->shlock();
        $hv{$_} = $$;
        $ipch->shunlock();
    }

    kill ALRM => $pid;
    waitpid($pid, 0);

    for (qw(fee fie foe fum)) {
        is $hv{$_}, $pid, "parent: HV $_ has val $pid";
    }

    for (qw(eenie meenie minie moe)) {
        is $hv{$_}, $$, "parent: HV $_ has val $$";
    }
}

IPC::Shareable::_end;
warn "Segs After: " . IPC::Shareable::ipcs() . "\n" if $ENV{PRINT_SEGS};

#done_testing();
