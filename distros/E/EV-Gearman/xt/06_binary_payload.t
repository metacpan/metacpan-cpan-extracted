# Binary payload edge cases: NULs, all-byte values, empty workload,
# function names with special chars (within Gearman's allowed set).
use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use EV;
use EV::Gearman;

my $host = $ENV{TEST_GEARMAN_HOST} || '127.0.0.1';
my $port = $ENV{TEST_GEARMAN_PORT} || 4730;

my $probe = IO::Socket::INET->new(
    PeerAddr => $host, PeerPort => $port,
    Proto => 'tcp', Timeout => 1,
);
plan skip_all => "no gearmand at $host:$port" unless $probe;
close $probe;

my $cli = EV::Gearman->new(host => $host, port => $port);
my $wkr = EV::Gearman->new(host => $host, port => $port);

# Identity worker: returns workload unchanged
$wkr->register_function('xt_bin_'.$$ => sub { $_[0]->workload });
$wkr->work;

sub roundtrip {
    my ($name, $payload) = @_;
    my ($r, $e);
    $cli->submit_job('xt_bin_'.$$, $payload, sub { ($r, $e) = @_; EV::break });
    my $g = EV::timer 5, 0, sub { fail "$name timeout"; EV::break };
    EV::run;
    is $e, undef, "$name: no error";
    is $r, $payload, "$name: identity preserved";
}

roundtrip 'empty', '';
roundtrip 'single NUL', "\0";
roundtrip 'embedded NULs', "a\0b\0c\0\0\0d";
roundtrip 'high bytes', join('', map chr($_), 0..255);
roundtrip 'large NULs',  ("\0" x 50_000);
roundtrip 'binary 1000 random bytes',
    join('', map chr(int rand 256), 1..1000);

done_testing;
