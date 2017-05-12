#!perl -T
use Test::More;

use IO::Socket;
use Distributed::Process::Interface;

my @test = ( 'line 1', "line\t2", '/line 3', 'fourth line', '', 'ok' );
plan tests => 9;

my ($child, $parent) = IO::Socket->socketpair(PF_UNIX, SOCK_STREAM, PF_UNSPEC);
my $pid = fork;
die $! unless defined($pid);

if ($pid) {
    my $i = new Distributed::Process::Interface
	-in_handle => $child,
	-out_handle => $child,
    ;
    isa_ok($i, 'Distributed::Process::Interface');
    $parent->close();
    my @res = $i->wait_for_pattern(qr|/line 3|);
    is(~~@res, 3, '3 lines returned');
    is($res[0], 'line 1', 'expected result');
    is($res[1], "line\t2", 'expected result');
    is($res[2], "/line 3", 'expected result');

    @res = $i->wait_for_pattern(qr|^ok|);
    is(~~@res, 3, '3 lines returned');
    is($res[0], 'fourth line', 'expected result');
    is($res[1], '', 'expected result');
    is($res[2], "ok", 'expected result');

}
else {
    $child->close();
    my $i = new Distributed::Process::Interface
	-in_handle => $parent,
	-out_handle => $parent,
    ;
    $i->send(@test);
    sleep 1;
}
