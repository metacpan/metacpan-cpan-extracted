#!/usr/bin/env perl

use strict;
use warnings;

use Linux::PipeMagic qw/ syssendfile /;
use File::Temp qw/ tempdir /;
use File::Slurp qw/ read_file /;
use Test::More;
use IO::Socket::INET;
my $dir = tempdir(CLEANUP => 1);

my $TEST_SAMPLE = "hallo world\n";

{
    open(my $fh, ">", "$dir/master") or die $!;
    print $fh $TEST_SAMPLE;
    close $fh;
}

my $listen = IO::Socket::INET->new(
    LocalAddr => "127.0.0.1",
    Listen    => 1,
    Proto     => 'tcp',
);

my $pid = fork;
unless (defined $pid) {
    die "fork failed $!";
}

if ($pid==0) {
    open(my $fh_out, ">", "$dir/copy") or die $!;

    my $sock = $listen->accept();
    while (<$sock>) {
        print $fh_out $_;
    }

    exit 0;
}

my $port = $listen->sockport;
ok $port;
diag "listening on port $port";
$listen = undef;

my $sock = IO::Socket::INET->new(
    PeerAddr => '127.0.0.1',
    PeerPort => $port,
    Proto    => 'tcp',
);

isa_ok($sock, 'IO::Socket::INET');

open(my $fh_in, "<", "$dir/master") or die $!;

is(syssendfile($sock, $fh_in, -s $fh_in), -s $fh_in) or warn $!;

close $sock;
close $fh_in;

is(waitpid($pid, 0), $pid);

open(my $fh_test, "<", "$dir/master") or die $!;
is(read_file($fh_test), $TEST_SAMPLE);

done_testing();

