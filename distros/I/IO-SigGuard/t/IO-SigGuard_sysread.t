#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use IO::File ();

use IO::SigGuard ();

plan tests => 1;

#NB: not 'IGNORE'
$SIG{'QUIT'} = sub {};

my ($pr, $cw);

pipe( $pr, $cw ) or die $!;

$cw = IO::File->new_from_fd( fileno($cw), 'w' );

my $ppid = $$;

my $cpid = fork;
die $! if !defined $cpid;
$cpid or do {
    close $pr;

    $cw->blocking(0);

    my $rin = q<>;
    vec( $rin, fileno($cw), 1 ) = 1;

    my $rout;

    while (1) {
        if ( select undef, $rout = $rin, undef, undef ) {
            syswrite( $cw, ('x' x 32) ) or die $!;
        }
        kill 'QUIT', $ppid or die $!;

        #Without this it’s possible to trip Perl’s 120-signals limit.
        select undef, undef, undef, 0.01;
    }

    exit;
};

close $cw or die $!;

my $start = time;

my $secs = 8;

note "Thrashing IPC for $secs seconds to test EINTR resistance …";

while (time - $start < $secs) {
    IO::SigGuard::sysread( $pr, my $buf, 65536 ) or die $!;
}

kill 'KILL', $cpid or die $!;

ok 1;
