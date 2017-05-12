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
		my $reactor = Mojo::IOLoop->singleton->reactor;
		
		return {
			init_io_watcher => sub {
				my ($hdl, $r_cb, $w_cb) = @_;
				
				$reactor->io($hdl => sub {
					my $writable = pop;
					
					if ($writable) {
						$w_cb->();
					}
					else {
						$r_cb->();
					}
				});
			},
			set_read_watcher => sub {
				my ($hdl, $cb) = @_;
				$reactor->watch($hdl, 1, 0);
			},
			unset_read_watcher => sub {
				my $hdl = shift;
				$reactor->watch($hdl, 0, 0);
			},
			set_write_watcher => sub {
				my ($hdl, $cb) = @_;
				$reactor->watch($hdl, 0, 1);
			},
			unset_write_watcher => sub {
				my $hdl = shift;
				$reactor->watch($hdl, 0, 0);
			},
			destroy_io_watcher => sub {
				my $hdl = shift;
				$reactor->remove($hdl);
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
	require Mojolicious;
	Mojolicious->VERSION(4.85); # next_tick
	require Mojo::IOLoop;
	require Mojo::UserAgent;
};
if ($@) {
	kill 15, $s_pid;
	plan skip_all => 'Mojolicious 4.85+ required for this test';
}

my ($h_pid, $h_host, $h_port) = make_http_server();

my $ua = Mojo::UserAgent->new(connect_timeout => 10);

my $tick_cnt = 0;
Mojo::IOLoop->recurring(0.5 => sub {
	$tick_cnt++;
});

diag '5 sec for next test';
my $in_progress = 2;

$ua->get("http://$h_host:$h_port/index", sub {
	my $tx = pop;
	ok($tx->success, 'first HTTP request success');
	is($tx->res->body, 'INDEX', 'first HTTP response was correct');
	Mojo::IOLoop->stop() unless --$in_progress;
});

$ua->get("http://$h_host:$h_port/", sub {
	my $tx = pop;
	ok($tx->success, 'second HTTP request success');
	is($tx->res->body, 'ROOT', 'second HTTP response was correct');
	Mojo::IOLoop->stop() unless --$in_progress;
});

Mojo::IOLoop->start();

ok($tick_cnt > 5, 'making socks handshake didn\'t block event loop')
	or diag $tick_cnt;

diag '2 sec for next test';
$destroyed = 0;
$ua->connect_timeout(2);
my $start = time;
$ua->get("http://$h_host:$h_port/", sub {
	my $tx = pop;
	ok(!$tx->success, 'HTTP request was not successfull because of timeout');
	like($tx->error->{message}, qr/time/i, 'Correct error occured');
	ok(time() - $start < 5, 'Timed out by event loop');
	Mojo::IOLoop->next_tick(sub { 
		is($destroyed, 1, 'socks handshake watcher destroyed');
		Mojo::IOLoop->stop();
	});
});

Mojo::IOLoop->start();

# ask socks server to return error instead of successfull socks handshake
kill 10, $s_pid;
$ua->get("http://$h_host:$h_port/", sub {
	my $tx = pop;
	ok(!$tx->success, 'HTTP response was not successfull because of socks handshake error');
	diag $tx->error->{message};
	Mojo::IOLoop->stop();
});

Mojo::IOLoop->start();

kill 15, $s_pid;
kill 15, $h_pid;

done_testing;
