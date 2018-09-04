#!/usr/bin/env perl

use strict;
use warnings;
use autodie;

use FindBin;
use lib "$FindBin::Bin/lib";
use LP_EnsureArch;

LP_EnsureArch::ensure_support('epoll');

use File::Temp;

use Test::More;
use Test::Deep;
use Test::FailWarnings -allow_deps => 1;
use Test::SharedFork;

use Socket;

use Linux::Perl::epoll;

for my $generic_yn ( 0, 1 ) {
    if ( my $pid = fork ) {
        waitpid $pid, 0;
        die if $?;
    }
    else {
        eval {
            my $class = 'Linux::Perl::epoll';
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

    {
        my $epl = $class->new();
        my $fileno = $epl->[0];

        my $no_cloexec = `$^X -e'print readlink "/proc/self/fd/$fileno"'`;
        ok( !$no_cloexec, 'CLOEXEC by default' );

        local $^F = 1000;

        $epl = $class->new();
        $fileno = $epl->[0];

        $no_cloexec = `$^X -e'print readlink "/proc/self/fd/$fileno"'`;
        ok( $no_cloexec, 'no CLOEXEC if $^F is high' );

        $epl = $class->new( flags => ['CLOEXEC'] );
        $fileno = $epl->[0];

        $no_cloexec = `$^X -e'print readlink "/proc/self/fd/$fileno"'`;
        ok( !$no_cloexec, 'CLOEXEC if $^F is high but CLOEXEC is given' );
    }

    pipe( my $r, my $w );

    my $epl = $class->new();
    $epl->add( $r, events => ['IN'] );

    my %events = $epl->wait( maxevents => 1, timeout => 0.1 );

    cmp_deeply( \%events, {}, 'no read events' ) or diag explain \%events;

    syswrite( $w, 'x' );

    %events = $epl->wait( maxevents => 1, timeout => 0.1 );

    cmp_deeply(
        \%events,
        { fileno($r) => $epl->EVENT_NUMBER()->{'IN'} },
        'received an event',
    ) or diag explain \%events;

    {
        sysread( $r, my $buf, 1 );  #flush buffer
    }

    #----------------------------------------------------------------------

    $epl = $class->new();
    $epl->add( $r, events => ['IN'] );

    # Just test out the signal blocking.
    () = $epl->wait( maxevents => 1, timeout => 0.1, sigmask => ['INT'] );

    syswrite( $w, 'x' );

    $epl->delete( $r );

    %events = $epl->wait( maxevents => 1, timeout => 0.1 );
    is_deeply( \%events, {}, 'delete() removes an event' );

    #----------------------------------------------------------------------

    socketpair my $yin, my $yang, Socket::AF_UNIX(), Socket::SOCK_STREAM(), 0;

    $epl->add( $yin, events => ['IN'] );
    $epl->modify( $yin, events => ['OUT'] );

    %events = $epl->wait( maxevents => 1, timeout => 0.1 );

    cmp_deeply(
        \%events,
        { fileno($yin) => $epl->EVENT_NUMBER()->{'OUT'} },
        'received expected event after modify()',
    ) or diag explain %events;

    close $yang;

    %events = $epl->wait( maxevents => 1, timeout => 0.1 );

    cmp_deeply(
        \%events,
        { fileno($yin) => $epl->EVENT_NUMBER()->{'OUT'} | $epl->EVENT_NUMBER()->{'HUP'} },
        'received expected event(s) after closing one end of a socketpair',
    ) or diag explain \%events;

    #----------------------------------------------------------------------

    pipe( $r, $w );

    $epl = $class->new();

    $epl->add( $r, events => ['IN', 'ET'] );

    syswrite( $w, 'xx' );

    () = $epl->wait( maxevents => 1, timeout => 0.1 );

    {
        sysread $r, my $buf, 1;
    }

    %events = $epl->wait( maxevents => 1, timeout => 0.1 );
    is_deeply( \%events, {}, 'edge-triggered flag works' ) or diag explain \%events;

    #----------------------------------------------------------------------

    {
        my $epl = $class->new();
        my $fileno = $epl->[0];

        undef $epl;

        ok( (!-e "/proc/$$/fd/$fileno"), 'epoll FD closed on DESTROY' );

        #----------------------------------------------------------------------

        $epl = $class->new( flags => ['CLOEXEC'] );
        $fileno = $epl->[0];

        undef $epl;

        ok( (!-e "/proc/$$/fd/$fileno"), 'epoll (CLOEXEC) FD closed on DESTROY' );
    }

    return;
}

done_testing();
