#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use IO::File ();

use IO::SigGuard ();

plan tests => 1;

#NB: not 'IGNORE'
$SIG{'QUIT'} = sub {};

my ($cr, $pw);

pipe( $cr, $pw ) or die $!;

$cr = IO::File->new_from_fd( fileno($cr), 'r' );

my $ppid = $$;

my $cpid = fork;
die $! if !defined $cpid;
$cpid or do {
    close $pw or die;

    $cr->blocking(0);

    my $rin = q<>;
    vec( $rin, fileno($cr), 1 ) = 1;

    my $rout;

    while (1) {
        if ( select $rout = $rin, undef, undef, undef ) {
            sysread( $cr, my $buf, 65536 ) or die $!;
        }

        #Without this it’s possible to trip Perl’s 120-signals limit.
        select undef, undef, undef, 0.01;
    }

    exit;
};

close $cr or die $!;

my $start = time;

my $secs = 8;

note "Thrashing IPC for $secs seconds to test EINTR resistance …";

while (time - $start < $secs) {
    IO::SigGuard::syswrite( $pw, 'x' x 64 ) or die $!;
}

kill 'KILL', $cpid or die $!;

ok 1;
