use strict;
use Test::More;
our ($s_pid, $s_host, $s_port);
BEGIN {
	if ($^O !~ /MSWin/i) {
		if ($ENV{SOCKS_WRAPPER_SLOW_TESTS} || $ENV{AUTOMATED_TESTING} || $ENV{EXTENDED_TESTING}) {
			pipe(READER, WRITER);
			my $child = fork();
			die 'fork: ', $! unless defined $child;
			
			if ($child == 0) {
				close READER;
				require 't/subs.pm';
				
				print WRITER join(',', make_socks_server(5, 5)), "\n";
				
				exit;
			}
			
			close WRITER;
			chomp(my $info = <READER>);
			close READER;
			($s_pid, $s_host, $s_port) = split /,/, $info;
		}
		else {
			plan skip_all => "SOCKS_WRAPPER_SLOW_TESTS environment variable should has true value to run this tests";
		}
	}
	else {
		plan skip_all => "No windows support for this test";
	}
}
use IO::Socket::Socks::Wrapper {
	ProxyAddr => $s_host,
	ProxyPort => $s_port,
	Timeout   => 2
};
use lib 't';
use Connect;
require 't/subs.pm';

diag "2 sec for next test";
my $start = time;

my ($h_pid, $h_host, $h_port) = make_http_server();

ok(!Connect::make($h_host, $h_port), 'Connection timed out');
my $timeout = time() - $start;
ok($timeout < 5, "timeout < 5") or diag "timeout is $timeout";

kill 15, $h_pid;
kill 15, $s_pid;

done_testing();
