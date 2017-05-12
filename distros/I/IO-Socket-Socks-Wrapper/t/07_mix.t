use strict;
use Test::More;
BEGIN {
	if ($^O =~ /MSWin/i) {
		plan skip_all => "Can't run this test on Windows";
	}
	else {
		pipe(READER, WRITER);
		my $child = fork();
		die 'fork: ', $! unless defined $child;
		
		if ($child == 0) {
			close READER;
			
			eval {
				require Net::FTP;
				require HTTP::Tiny;
			};
			
			print WRITER $@ ? 0 : 1, "\n";
			
			exit;
		}
		
		close WRITER;
		chomp(my $success = <READER>);
		close READER;
		
		if ($success) {
			require 't/subs.pm';
			our ($fs_pid, $fs_host, $fs_port) = make_socks_server(5);
			our ($hs_pid, $hs_host, $hs_port) = make_socks_server(4);
			our ($cs_pid, $cs_host, $cs_port) = make_socks_server(5);
			our ($h_pid, $h_host, $h_port) = make_http_server();
			our ($f_pid, $f_host, $f_port) = make_ftp_server();
		}
		else {
			plan skip_all => "Net::FTP or HTTP::Tiny was not found";
		}
	}
	
	$ENV{http_proxy} = $ENV{HTTP_PROXY} = 
	$ENV{https_proxy} = $ENV{HTTPS_PROXY} = 
	$ENV{all_proxy} = $ENV{ALL_PROXY} = undef;
}

use HTTP::Tiny;
use lib 't';
use IO::Socket::Socks::Wrapper (
	'Net::FTP' => {
		ProxyAddr => our $fs_host,
		ProxyPort => our $fs_port,
	},
	'HTTP::Tiny::Handle::connect()' => {
		ProxyAddr    => our $hs_host,
		ProxyPort    => our $hs_port,
		SocksVersion => 4
	},
	'Connect' => {
		_norequire   => 1,
		ProxyAddr    => our $cs_host,
		ProxyPort    => our $cs_port,
		SocksVersion => 5
	}
);
use Connect;

our ($h_pid, $h_host, $h_port);
our ($f_pid, $f_host, $f_port);

ok(eval{Net::FTP->new("$f_host:$f_port")->login('root', 'toor')}, "ftp +socks server");
kill 15, our $fs_pid;
ok(!eval{Net::FTP->new("$f_host:$f_port")->login('root', 'toor')}, "ftp -socks server");
IO::Socket::Socks::Wrapper->import('Net::FTP' => 0);
ok(eval{Net::FTP->new("$f_host:$f_port")->login('root', 'toor')}, "ftp +direct network access");

my $http = HTTP::Tiny->new();
is($http->get("http://$h_host:$h_port/")->{content}, 'ROOT', "http +socks server");
kill 15, our $hs_pid;
isnt($http->get("http://$h_host:$h_port/")->{content}, 'ROOT', "http -socks server");
IO::Socket::Socks::Wrapper->import('HTTP::Tiny::Handle::connect()' => 0);
is($http->get("http://$h_host:$h_port/")->{content}, 'ROOT', "http +direct network access");
kill 15, our $h_pid;

ok(Connect::make($f_host, $f_port), "built-in +socks server");
kill 15, our $cs_pid;
ok(!Connect::make($f_host, $f_port), "built-in -socks server");
IO::Socket::Socks::Wrapper->import('Connect' => 0);
ok(Connect::make($f_host, $f_port), "built-in +direct network access");
kill 15, our $f_pid;

done_testing();
