#!/usr/bin/env perl

use Test::More;
use IO::Socket::Socks::Wrapper;
require 't/subs.pm';
use strict;

$^W = 0;
$ENV{http_proxy} = $ENV{HTTP_PROXY} = 
$ENV{https_proxy} = $ENV{HTTPS_PROXY} = 
$ENV{all_proxy} = $ENV{ALL_PROXY} = undef;

SKIP: {
	skip "fork, windows, sux" if $^O =~ /MSWin/i;
	eval { require Net::HTTP; require Net::FTP }
		or skip "No Net::HTTP or Net::FTP";
		
	my ($s_pid, $s_host, $s_port) = make_socks_server(4);
	my ($h_pid, $h_host, $h_port) = make_http_server();
	my ($f_pid, $f_host, $f_port) = make_ftp_server();
	
	IO::Socket::Socks::Wrapper->import(
		Net::FTP:: => {
			ProxyAddr => $s_host,
			ProxyPort => $s_port,
			SocksVersion => 4
		}
	);
	
	my $ftp = Net::FTP->new($f_host, Port => $f_port)
		or warn $@;
	if ($ftp) {
		ok($ftp->login('root', 'toor'), 'Socks4+Server Login')
			or diag $ftp->message;
	}
		
	kill 15, $s_pid;
	ok(!eval{Net::FTP->new($f_host, Port => $f_port)->login('root', 'toor')}, 'Socks4-Server Login');
	
	my $http = Net::HTTP->new(Host => $h_host, PeerPort => $h_port);
	my $page;
	eval {
		$http->write_request(GET => '/stuff');
		$http->read_response_headers();
		$http->read_entity_body($page, 1024);
	};
	
	skip "You are behind squid" if $page =~ /squid/i;
	is($page, 'UNKNOWN', 'Direct http connection');
	kill 15, $h_pid;
	kill 15, $f_pid;
};

SKIP: {
	skip "fork, windows, sux" if $^O =~ /MSWin/i;
	eval { require LWP::UserAgent; require LWP::Protocol::http; require Net::HTTP }
		or skip "No LWP found";
		
	my ($s_pid, $s_host, $s_port) = make_socks_server(5);
	my ($h_pid, $h_host, $h_port) = make_http_server();
	
	IO::Socket::Socks::Wrapper->import(
		'LWP::Protocol::http::Socket' => {
			ProxyAddr => $s_host,
			ProxyPort => $s_port,
			SocksVersion => 5
		}
	);
	
	my $ua = LWP::UserAgent->new();
	my $page = $ua->get("http://$h_host:$h_port/")->content;
	skip "You are behind squid" if $page =~ /squid/i;
	is($page, 'ROOT', 'LWP+Socks5+Server');
	
	kill 15, $s_pid;
	$page = $ua->get("http://$h_host:$h_port/")->content;
	isnt($page, 'ROOT', 'LWP+Socks5-Server');
	
	my $http = Net::HTTP->new(Host => $h_host, PeerPort => $h_port);
	$page = '';
	eval {
		$http->write_request(GET => '/');
		$http->read_response_headers();
		$http->read_entity_body($page, 1024);
	};
	is($page, 'ROOT', 'Net::HTTP direct');
	
	kill 15, $h_pid;
};

done_testing();
