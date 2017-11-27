#!/usr/bin/env perl

use strict;
use warnings;
use autodie;

use Test::More;

use File::Temp ();

use IO::File ();

use IO::SigGuard ();

plan tests => 13;

my $sigs_received = 0;

$SIG{'QUIT'} = sub {
    $sigs_received++;
    diag "$$ got $_[0]";
};

my $ppid = $$;

my $spawn_killer = sub {
    $sigs_received = 0;

    my $pid = fork or do {
        for (1 .. 20) {
            kill 'QUIT', $ppid;
            diag "$$ sent SIGQUIT";

            select( undef, undef, undef, 0.5 );
        }
        exit;
    };

    return $pid;
};

my $pid = $spawn_killer->();

my $nfound = IO::SigGuard::select( undef, undef, undef, 5 );

my $os_error = $!;

kill 'KILL', $pid;
waitpid $pid, 0;

cmp_ok( $sigs_received, '>=', 2, 'got signals' );
is( $nfound, 0, '… but nothing to read (scalar)' );

{
    local $! = $os_error;
    ok( !$!{'EINTR'}, '… and $! is not EINTR' ) or diag "$os_error";
}

my $timeleft;

$pid = $spawn_killer->();

($nfound, $timeleft) = IO::SigGuard::select( undef, undef, undef, 5 );

$os_error = $!;

kill 'KILL', $pid;
waitpid $pid, 0;

cmp_ok( $sigs_received, '>=', 2, 'got signals' );
is( $nfound, 0, '… but nothing to read (list)' );
is( $timeleft, 0, '… and no time left (list)' );

{
    local $! = $os_error;
    ok( !$!{'EINTR'}, '… and $! is not EINTR' ) or diag "$os_error";
}

#----------------------------------------------------------------------

SKIP: {
    if ( $^O eq 'MSWin32' ) {
        skip 'Windows select() only does sockets.', 6;
    }

    my ($fh, $fpath) = File::Temp::tempfile( CLEANUP => 1 );
    my $in = q<>;
    vec( $in, fileno($fh), 1 ) = 1;

    my $out;

    $nfound = IO::SigGuard::select( undef, $out = $in, undef, 30 );

    is( $nfound, 1, 'select() gives write as expected (scalar)' );

    ($nfound, $timeleft) = IO::SigGuard::select( undef, $out = $in, undef, 30 );

    is( $nfound, 1, 'select() gives write as expected (list)' );
    cmp_ok( $timeleft, '<=', 30, '… and time left is as expected' );

    syswrite( $fh, 'x' );
    sysseek( $fh, 0, 0 );

    $nfound = IO::SigGuard::select( $out = $in, undef, undef, 30 );

    is( $nfound, 1, 'select() gives read as expected (scalar)' );

    ($nfound, $timeleft) = IO::SigGuard::select( $out = $in, undef, undef, 30 );

    is( $nfound, 1, 'select() gives read as expected (list)' );
    cmp_ok( $timeleft, '<=', 30, '… and time left is as expected' );
}
