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
	eval { require HTTP::Tiny  }
		or skip "No HTTP::Tiny found";
	
	my ($s_pid, $s_host, $s_port) = make_socks_server(5);
	my ($h_pid, $h_host, $h_port) = make_http_server();
	
	IO::Socket::Socks::Wrapper->import(
		'HTTP::Tiny::Handle::connect()' => {
			ProxyAddr => $s_host,
			ProxyPort => $s_port,
		}
	);
	
	my $http = HTTP::Tiny->new();
	is($http->get("http://$h_host:$h_port/")->{content}, 'ROOT', 'HTTP::Tiny::Handle::connect() +Socks5 server');
	
	kill 15, $s_pid;
	isnt($http->get("http://$h_host:$h_port/")->{content}, 'ROOT', 'HTTP::Tiny::Handle::connect() -Socks5 server');
	
	IO::Socket::Socks::Wrapper->import(
		'HTTP::Tiny::Handle::connect()' => 0
	);
	
	is($http->get("http://$h_host:$h_port/")->{content}, 'ROOT', 'HTTP::Tiny::Handle::connect() +direct network access');
	kill 15, $h_pid;
};

done_testing();
