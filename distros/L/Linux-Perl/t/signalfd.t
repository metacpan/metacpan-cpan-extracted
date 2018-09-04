#!/usr/bin/env perl

use strict;
use warnings;
use autodie;

use FindBin;
use lib "$FindBin::Bin/lib";
use LP_EnsureArch;

LP_EnsureArch::ensure_support('signalfd');
LP_EnsureArch::ensure_support('sigprocmask');

use File::Temp;

use Test::More;
use Test::Deep;
use Test::FailWarnings -allow_deps => 1;
use Test::SharedFork;

use Config;
use Socket;

use Linux::Perl::signalfd;
use Linux::Perl::sigprocmask;

for my $generic_yn ( 0, 1 ) {
    if ( my $pid = fork ) {
        waitpid $pid, 0;
        die if $?;
    }
    else {
        eval {
            my $class = 'Linux::Perl::signalfd';
            if (!$generic_yn) {
                require Linux::Perl::ArchLoader;
                $class = Linux::Perl::ArchLoader::get_arch_module($class);
            };

            _do_tests($class);
        };
        die if $@;
        exit;
    }
}

sub _do_tests {
    my ($class) = @_;

    note "Using class: $class (PID $$)";

    my $sfd = $class->new(
        signals => ['USR1'],
        flags => ['NONBLOCK'],
    );

    Linux::Perl::sigprocmask->block('USR1');
    my @old = Linux::Perl::sigprocmask->block('USR2');

    kill 'USR1', $$;

    my ($siginfo_hr) = $sfd->read();

    my %sig_num;
    my @names = split ' ', $Config::Config{sig_name};
    @sig_num{@names} = split ' ', $Config::Config{sig_num};

    cmp_deeply(
        $siginfo_hr,
        {
            'overrun' => 0,
            'status' => 0,
            'errno' => 0,
            'fd' => 0,
            'pid' => $$,
            'uid' => $>,
            'band' => 0,
            'stime' => 0,
            'code' => 0,
            'ptr' => 0,
            'trapno' => 0,
            'signo' => $sig_num{'USR1'},
            'addr' => 0,
            'tid' => 0,
            'addr_lsb' => 0,
            'int' => 0,
            'utime' => 0,
        },
        'siginfo after USR1',
    );

    $sfd->set_signals('USR2');

    kill 'USR2', $$;

    ($siginfo_hr) = $sfd->read();

    cmp_deeply(
        $siginfo_hr,
        {
            'overrun' => 0,
            'status' => 0,
            'errno' => 0,
            'fd' => 0,
            'pid' => $$,
            'uid' => $>,
            'band' => 0,
            'stime' => 0,
            'code' => 0,
            'ptr' => 0,
            'trapno' => 0,
            'signo' => $sig_num{'USR2'},
            'addr' => 0,
            'tid' => 0,
            'addr_lsb' => 0,
            'int' => 0,
            'utime' => 0,
        },
        'siginfo after USR2',
    );
}

done_testing();
