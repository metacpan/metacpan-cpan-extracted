use strict;
use warnings;
use Test::More;
use EV;
use EV::ClickHouse;

my $host = $ENV{TEST_CLICKHOUSE_HOST} || '127.0.0.1';
require IO::Socket::INET;
my @protos = grep { IO::Socket::INET->new(PeerAddr => $host, PeerPort => $_->[1], Timeout => 2) }
    ([native => $ENV{TEST_CLICKHOUSE_NATIVE_PORT} || 9000], [http => $ENV{TEST_CLICKHOUSE_PORT} || 8123]);
plan skip_all => 'ClickHouse not reachable' unless @protos;

my @values = ("a\tb", "a\nb", "a\rb", 'a\\b', "a\\tb", "it's", "x\0y", "\\", "tab\t\\\n'end");

for my $p (@protos) {
    my ($proto, $port) = @$p;
    my $ok;
    my $ch = EV::ClickHouse->new(host => $host, port => $port, protocol => $proto,
                                 on_connect => sub { $ok = 1; EV::break }, on_error => sub { diag("error: $_[0]") });
    my $t = EV::timer(10, 0, sub { EV::break });
    EV::run until $ok;
    my $fmt = $proto eq 'http' ? ' format TabSeparated' : '';
    for my $v (@values) {
        my ($r, $e, $d);
        $ch->query("select {s:String}, length({s:String})$fmt", { params => { s => $v } },
                   sub { ($r, $e) = @_; $d = 1; EV::break });
        my $g = EV::timer(10, 0, sub { $e //= 'timed out'; EV::break });
        EV::run until $d || $e;
        (my $show = $v) =~ s/([^\x20-\x7e])/sprintf '\\x%02x', ord $1/ge;
        is_deeply($e ? $e : $r, [[$v, length $v]], "$proto: parameter '$show' round-trips");
    }
    $ch->finish;
}

done_testing;
