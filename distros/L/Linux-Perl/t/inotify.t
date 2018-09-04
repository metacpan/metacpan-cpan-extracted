#!/usr/bin/env perl

use strict;
use warnings;
use autodie;

use FindBin;
use lib "$FindBin::Bin/lib";
use LP_EnsureArch;

LP_EnsureArch::ensure_support('inotify');

use File::Temp;
use File::Slurp;

use Test::More;
use Test::Deep;
use Test::FailWarnings -allow_deps => 1;
use Test::SharedFork;

use Socket;

use Linux::Perl::inotify;

for my $generic_yn ( 0, 1 ) {
    if ( my $pid = fork ) {
        waitpid $pid, 0;
        die if $?;
    }
    else {
        eval {
            my $class = 'Linux::Perl::inotify';
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

    cmp_bag(
        [ keys %{ $class->EVENT_NUMBER() } ],
        [
            'ACCESS',
            'MODIFY',
            'ATTRIB',
            'CLOSE_WRITE',
            'CLOSE_NOWRITE',
            'OPEN',
            'MOVED_FROM',
            'MOVED_TO',
            'CREATE',
            'DELETE',
            'DELETE_SELF',
            'MOVE_SELF',
            'UNMOUNT',
            'Q_OVERFLOW',
            'IGNORED',
            'ISDIR',
            'CLOSE',
            'MOVE',
        ],
        'all expected EVENT_NUMBER() members',
    ) or diag explain $class->EVENT_NUMBER();

    my $dir = File::Temp::tempdir( CLEANUP => 1 );

    my $inotify = eval {
        $class->new( flags => [ 'NONBLOCK' ] );
    };
    if (!$inotify) {
        my $err = $@ or die "no inotify but no error?";

        if ($err->get('error') == Errno::EMFILE()) {
            diag "inotify init failed: $@";

            for my $in_stat ( qw( user_instances user_watches queued_events ) ) {
                my $node = "/proc/sys/fs/inotify/max_$in_stat";
                my $val = File::Slurp::read_file($node);

                diag "$node: $val";
            }

            #diag "inotify instances for UID $>:";
            #diag q<> . `for foo in /proc/*/fd/*; do readlink -f \$foo; done | grep ':inotify' | sort | uniq -c | sort -nr | awk '{print; s+=\$1} END {print s}'`;
            #diag q<> . `ps aux`;

            return;
        }

        local $@ = $err;
        die;
    }

    my $wd = $inotify->add( path => $dir, events => [ 'ONLYDIR', 'DONT_FOLLOW', 'ALL_EVENTS' ] );

    $inotify->read();

    ok( $!{'EAGAIN'}, 'EAGAIN when a non-blocking inotify does empty read()' );

    do { open my $wfh, '>', "$dir/thefile" };

    chmod 0765, $dir;   # a quasi-nonsensical mode

    rename "$dir/thefile" => "$dir/thefile2";

    unlink "$dir/thefile2";

    $inotify->remove($wd);

    # This will NOT be picked up by the inotify because
    # of the remove() just above.
    do { open my $wfh, '>', "$dir/thefile" };

    my @events = $inotify->read();

    cmp_bag(
        \@events,
        [
            {
                wd => $wd,
                cookie => 0,
                mask => $inotify->EVENT_NUMBER()->{'CREATE'},
                name => 'thefile',
            },
            {
                wd => $wd,
                cookie => 0,
                mask => $inotify->EVENT_NUMBER()->{'OPEN'},
                name => 'thefile',
            },
            {
                wd => $wd,
                cookie => 0,
                mask => $inotify->EVENT_NUMBER()->{'ATTRIB'} | $inotify->EVENT_NUMBER()->{'ISDIR'},
                name => q<>,
            },
            {
                wd => $wd,
                cookie => ignore(),
                mask => $inotify->EVENT_NUMBER()->{'MOVED_FROM'},
                name => 'thefile',
            },
            {
                wd => $wd,
                cookie => ignore(),
                mask => $inotify->EVENT_NUMBER()->{'MOVED_TO'},
                name => 'thefile2',
            },
            {
                wd => $wd,
                cookie => 0,
                mask => $inotify->EVENT_NUMBER()->{'DELETE'},
                name => 'thefile2',
            },
            {
                wd => $wd,
                cookie => 0,
                mask => $inotify->EVENT_NUMBER()->{'IGNORED'},
                name => q<>,
            },
        ],
        'create chmod, unlink, rmdir events',
    ) or diag explain \@events;

    my @move_evts = grep { $_->{'mask'} & $inotify->EVENT_NUMBER()->{'MOVE'} } @events;

    is(
        $move_evts[0]{'cookie'},
        $move_evts[1]{'cookie'},
        'move cookie values match',
    );

    return;
}

done_testing();
