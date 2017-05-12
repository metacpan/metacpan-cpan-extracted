#!/usr/bin/env perl

BEGIN {
	if ($^O !~ /MSWin/i) {
		pipe(READER, WRITER);
		my $child = fork();
		die 'fork: ', $! unless defined $child;
		
		if ($child == 0) {
			close READER;
			require 't/subs.pm';
			
			print WRITER join(',', make_socks_server(5)), "\n";
			
			exit;
		}
		
		close WRITER;
		chomp(my $info = <READER>);
		close READER;
		($s_pid, $s_host, $s_port) = split /,/, $info;
	}
}

use IO::Socket::Socks::Wrapper {
	ProxyAddr => $s_host,
	ProxyPort => $s_port
};
use Socket;
use Test::More;
require 't/subs.pm';

$^W = 0;
$ENV{http_proxy} = $ENV{HTTP_PROXY} = 
$ENV{https_proxy} = $ENV{HTTPS_PROXY} = 
$ENV{all_proxy} = $ENV{ALL_PROXY} = undef;

SKIP: {
	skip "fork, windows, sux" if $^O =~ /MSWin/i;
	eval { require LWP; require Net::HTTP; require Net::FTP }
		or skip "No LWP or Net::FTP found";
	
	if (%IO::Socket::IP:: && $IO::Socket::IP::VERSION >= 0.08 && $IO::Socket::IP::VERSION < 0.35) {
		skip "IO::Socket::IP with non overridable CORE::connect detected";
	}
	
	my ($h_pid, $h_host, $h_port) = make_http_server();
	my ($f_pid, $f_host, $f_port) = make_ftp_server();
	
	my $ua = LWP::UserAgent->new;
	my $page = $ua->get("http://$h_host:$h_port/")->content;
	is($page, 'ROOT', 'LWP+Global socks5');
	
	socket(SOCK, PF_INET, SOCK_STREAM, getprotobyname('tcp'));
	ok(connect(SOCK, sockaddr_in($h_port, inet_aton($h_host))), 'Bareword connect');
	close SOCK;
	
	socket(my $sock, PF_INET, SOCK_STREAM, getprotobyname('tcp'));
	ok(connect($sock, sockaddr_in($h_port, inet_aton($h_host))), 'GLOB connect');
	close $sock;
	
	my $ftp = Net::FTP->new($f_host, Port => $f_port)
		or warn $@;
	if ($ftp) {
		ok($ftp->login('root', 'toor'), 'Net::FTP login+Global socks5')
			or diag $ftp->message;
	}
	
	kill 15, $s_pid;
	$s_pid = undef;
	
	socket(NEW_SOCK, PF_INET, SOCK_STREAM, getprotobyname('tcp'));
	ok(!connect(NEW_SOCK, sockaddr_in($h_port, inet_aton($h_host))), 'Bareword connect -Server');
	close NEW_SOCK;
	
	socket(my $new_sock, PF_INET, SOCK_STREAM, getprotobyname('tcp'));
	ok(!connect($new_sock, sockaddr_in($h_port, inet_aton($h_host))), 'GLOB connect -Server');
	close $new_sock;
	
	$page = $ua->get("http://$h_host:$h_port/")->content;
	isnt($page, 'ROOT', 'LWP+Global socks5 -Server');
	
	ok(!eval{Net::FTP->new($f_host, Port => $f_port)->login('root', 'toor')}, 'Net::FTP login+Global socks5 -Server');
	
	IO::Socket::Socks::Wrapper->import(Net::FTP:: => 0);
	$ftp = Net::FTP->new($f_host, Port => $f_port)
		or warn $@;
	if ($ftp) {
		ok($ftp->login('root', 'toor'), 'Net::FTP login+Disabled wrapper for Net::FTP')
			or diag $ftp->message;
	}
	
	kill 15, $h_pid;
	kill 15, $f_pid;
};

kill 15, $s_pid if $s_pid;

done_testing();
