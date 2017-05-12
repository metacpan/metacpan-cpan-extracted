use strict;
use Test::More;
our ($s_pid, $s_host, $s_port);
BEGIN {
	if ($^O !~ /MSWin/i) {
		if ($ENV{SOCKS_WRAPPER_SLOW_TESTS} || $ENV{AUTOMATED_TESTING} || $ENV{EXTENDED_TESTING}) {
			require 't/subs.pm';
			($s_pid, $s_host, $s_port) = make_socks_server(4, 5);
		}
		else {
			plan skip_all => "SOCKS_WRAPPER_SLOW_TESTS environment variable should has true value to run this tests";
		}
	}
	else {
		plan skip_all => "No windows support for this test";
	}
	
	$ENV{PERL_HTTP_TINY_IPV4_ONLY} = 1;
	$ENV{http_proxy} = $ENV{HTTP_PROXY} = 
	$ENV{https_proxy} = $ENV{HTTPS_PROXY} = 
	$ENV{all_proxy} = $ENV{ALL_PROXY} = undef;
}
use IO::Socket::Socks::Wrapper (
	Connect => {
		_norequire   => 1,
		ProxyAddr    => $s_host,
		ProxyPort    => $s_port,
		SocksVersion => 4,
		Timeout      => 2
	}
);
use lib 't';
use Connect;

my ($f_pid, $f_host, $f_port) = make_ftp_server();
diag "2 sec for next test";
my $start = time;
ok(!Connect::make($f_host, $f_port), "built-in timed out");
my $timeout = time() - $start;
ok($timeout < 5, "timeout < 5") or diag "timeout=$timeout";

IO::Socket::Socks::Wrapper->import(
	'Net::FTP' => {
		ProxyAddr    => $s_host,
		ProxyPort    => $s_port,
		SocksVersion => 4,
		Timeout      => 2
	}
);

diag "2 sec for next test";
$start = time;
ok(!Net::FTP->new("$f_host:$f_port"), "inherited from IO::Socket timed out");
$timeout = time() - $start;
ok($timeout < 5, "timeout < 5") or diag "timeout=$timeout";
kill 15, $f_pid;

my ($h_pid, $h_host, $h_port) = make_http_server();

SKIP: {
	eval {require HTTP::Tiny } or skip "HTTP::Tiny not installed";
	
	IO::Socket::Socks::Wrapper->import(
		'HTTP::Tiny::Handle::connect()' => {
			ProxyAddr    => $s_host,
			ProxyPort    => $s_port,
			SocksVersion => 4,
			Timeout      => 2
		}
	);
	
	diag "2 sec for next test";
	$start = time;
	isnt(HTTP::Tiny->new->get("http://$h_host:$h_port/")->{content}, 'ROOT', "internal IO::Socket timed out");
	$timeout = time() - $start;
	ok($timeout < 5, "timeout < 5") or diag "timeout=$timeout";
};

SKIP: {
	eval { require LWP::UserAgent } or skip "LWP::UserAgent not installed";
	
	my $ua = IO::Socket::Socks::Wrapper::wrap_connection(LWP::UserAgent->new(timeout => 2), {
		ProxyAddr    => $s_host,
		ProxyPort    => $s_port,
		SocksVersion => 4,
	});
	
	diag "2 sec for next test";
	$start = time;
	isnt($ua->get("http://$h_host:$h_port/")->content, 'ROOT', "wraped object timed out");
	$timeout = time() - $start;
	ok($timeout < 5, "timeout < 5") or diag "timeout=$timeout";
};

kill 15, $h_pid;
kill 15, $s_pid;

done_testing();
