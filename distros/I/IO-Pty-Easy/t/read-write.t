#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use IO::Pty::Easy;

my $pty = IO::Pty::Easy->new;

$pty->spawn("$^X -ple ''");
$pty->write("testing\n");
like($pty->read, qr/testing/, "basic read/write testing");
is($pty->read(0.1), undef, "read returns undef on timeout");
$pty->kill;

TODO: {
local $TODO = "this isn't a reliable way to produce a blocking write";
$pty->spawn("$^X -e 'sleep(1) while 1'");
eval {
    local $SIG{ALRM} = sub {
        is($pty->write("should fail", 0.1), undef,
           "write returns undef on timeout");
        $SIG{ALRM} = 'DEFAULT';
        alarm 1;
    };
    alarm 1;
    $pty->write('a'x(1024*1024));
};
$pty->kill;
$pty->close;
}

# create an entirely new pty to clear the input buffer
$pty = IO::Pty::Easy->new;
$pty->spawn("$^X -e 'sleep(1) while 1'");
my $result = "wrong";
$result = eval {
    local $SIG{ALRM} = sub { die "alarm\n" };
    alarm 2;
    my $write_result = $pty->write('a'x(1024*1024), 0.1);
    defined($write_result) ? "wrong" : "right";
};
TODO: {
    local $TODO = "need to figure this one out";
    is($result, "right", "write times out properly even on the first call");
    isnt($@, "alarm\n", "write times out properly even on the first call");
}

# if the perl script ends with a subprocess still running, the test will exit
# with the exit status of the signal that the subprocess dies with, so we have
# to kill the subprocess before exiting.
$pty->close;

done_testing;
