use strict;
use Test::More;

our ($s_pid, $s_host, $s_port);
our $destroyed;
BEGIN {
	if ($^O =~ /MSWin/i) {
		plan skip_all => 'Can\'t run this test on windows';
	}
	
	unless ($ENV{SOCKS_WRAPPER_SLOW_TESTS} || $ENV{AUTOMATED_TESTING} || $ENV{EXTENDED_TESTING}) {
		plan skip_all => "SOCKS_WRAPPER_SLOW_TESTS environment variable should has true value to run this tests";
	}
	
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

use IO::Socket::Socks::Wrapper {
	ProxyAddr   => $s_host,
	ProxyPort   => $s_port,
	_io_handler => sub {
		my $w;
		
		return {
			set_read_watcher => sub {
				my ($hdl, $cb) = @_;
				
				$w = AnyEvent->io(
					poll => 'r',
					fh   => $hdl,
					cb   => $cb
				)
			},
			unset_read_watcher => sub {
				undef $w;
			},
			set_write_watcher => sub {
				my ($hdl, $cb) = @_;
				
				$w = AnyEvent->io(
					poll => 'w',
					fh   => $hdl,
					cb   => $cb
				)
			},
			unset_write_watcher => sub {
				undef $w;
			},
			destroy_io_watcher => sub {
				$destroyed = 1;
			}
		}
	}
};

require 't/subs.pm';
$ENV{http_proxy} = $ENV{HTTP_PROXY} = 
$ENV{https_proxy} = $ENV{HTTPS_PROXY} = 
$ENV{all_proxy} = $ENV{ALL_PROXY} = undef;

eval {
	require AnyEvent;
	require AnyEvent::HTTP;
	AnyEvent::HTTP->import();
};
if ($@) {
	kill 15, $s_pid;
	plan skip_all => 'AnyEvent and AnyEvent::HTTP required for this test';
}

AnyEvent::detect();
if ($EV::VERSION && &EV::backend == &EV::BACKEND_KQUEUE) {
	kill 15, $s_pid;
	plan skip_all => 'kqueue support known to be broken';
}

my ($h_pid, $h_host, $h_port) = make_http_server();

my $tick_cnt = 0;
my $timer = AnyEvent->timer(
	after    => 0.5,
	interval => 0.5,
	cb       => sub {
		$tick_cnt++;
	}
);

diag '5 sec for next test';
my $cv = AnyEvent->condvar;
$cv->begin for 1..2;

http_get("http://$h_host:$h_port/index", timeout => 10, sub {
	my ($body, $hdr) = @_;
	
	ok($hdr->{Status} =~ /^2/, 'first HTTP request success') or diag "$hdr->{Status} - $hdr->{Reason}";
	is($body, 'INDEX', 'first HTTP response was correct');
	$cv->end;
});

http_get("http://$h_host:$h_port/", timeout => 10, sub {
	my ($body, $hdr) = @_;
	
	ok($hdr->{Status} =~ /^2/, 'second HTTP request success');
	is($body, 'ROOT', 'second HTTP response was correct');
	$cv->end;
});

$cv->recv;

ok($tick_cnt > 5, 'making socks handshake didn\'t block event loop')
	or diag $tick_cnt;

diag '2 sec for next test';
$destroyed = 0;
my $start = time;
$cv = AnyEvent->condvar;
$cv->begin;

http_get("http://$h_host:$h_port/", timeout => 2, sub {
	my ($body, $hdr) = @_;
	
	ok($hdr !~ /^2/, 'HTTP request was not successfull because of timeout');
	ok(time() - $start < 5, 'Timed out by event loop');
	is($destroyed, 1, 'socks handshake watcher destroyed');
	$cv->end;
});

$cv->recv;

# ask socks server to return error instead of successfull socks handshake
kill 10, $s_pid;

$cv = AnyEvent->condvar;
$cv->begin;

http_get("http://$h_host:$h_port/", sub {
	my ($body, $hdr) = @_;
	
	ok($hdr->{Status} !~ /^2/, 'HTTP response was not successfull because of socks handshake error');
	diag $hdr->{Reason};
	$cv->end;
});

$cv->recv;

kill 15, $s_pid;
kill 15, $h_pid;

done_testing;
