#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use IPC::SafeFork;

our( $child, $status );
$SIG{CHLD} = sub {
    $child = waitpid -1, 0;
    $status = $?;
};

my $parent = $$;

my $pid = safe_fork;
die "Unable to fork: $!" unless defined $pid;
exit 0 unless $pid;   # child

plan tests => 3;

# parent
isnt( $pid, $parent, "New child" );
sleep 1;
is( $child, $pid, "Exited" );
is( $status, 0, "OK" );
