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
	skip "no fork support" if $^O =~ /MSWin/i;
	eval { require LWP;  }
		or skip 'No LWP installed';
	
	my ($s_pid4, $s_host4, $s_port4) = make_socks_server(4);
	my ($s_pid5, $s_host5, $s_port5) = make_socks_server(5);
	
	my $ua4 = IO::Socket::Socks::Wrapper::wrap_connection(LWP::UserAgent->new(timeout => 10), {
		ProxyAddr    => $s_host4,
		ProxyPort    => $s_port4,
		SocksVersion => 4,
	});
	
	isa_ok($ua4, 'LWP::UserAgent');
	
	my $ua5 = IO::Socket::Socks::Wrapper::wrap_connection(LWP::UserAgent->new(timeout => 10), {
		ProxyAddr    => $s_host5,
		ProxyPort    => $s_port5,
		SocksVersion => 5,
	});
	
	isa_ok($ua5, 'LWP::UserAgent');
	
	my ($h_pid, $h_host, $h_port) = make_http_server();
	
	ok($ua4->get("http://$h_host:$h_port/")->is_success, 'ua4 request');
	ok($ua5->get("http://$h_host:$h_port/")->is_success, 'ua5 request');
	
	kill 15, $s_pid4;
	ok(!$ua4->get("http://$h_host:$h_port/")->is_success, 'ua4 request -server4');
	ok($ua5->get("http://$h_host:$h_port/")->is_success, 'ua5 request -server4');
	
	kill 15, $s_pid5;
	ok(!$ua5->get("http://$h_host:$h_port/")->is_success, 'ua5 request -server5');
	
	kill 15, $h_pid;
};

SKIP: {
	skip "no fork support" if $^O =~ /MSWin/i;
	eval { require HTTP::Tiny }
		or skip 'No HTTP::Tiny installed';
	
	my ($s_pid4, $s_host4, $s_port4) = make_socks_server(4);
	my ($s_pid5, $s_host5, $s_port5) = make_socks_server(5);
	
	my $ua4 = IO::Socket::Socks::Wrapper::wrap_connection(HTTP::Tiny->new(timeout => 10), {
		ProxyAddr    => $s_host4,
		ProxyPort    => $s_port4,
		SocksVersion => 4,
	});
	
	isa_ok($ua4, 'HTTP::Tiny');
	
	my $ua5 = IO::Socket::Socks::Wrapper::wrap_connection(HTTP::Tiny->new(timeout => 10), {
		ProxyAddr    => $s_host5,
		ProxyPort    => $s_port5,
		SocksVersion => 5,
	});
	
	isa_ok($ua5, 'HTTP::Tiny');
	
	my ($h_pid, $h_host, $h_port) = make_http_server();
	
	ok($ua4->get("http://$h_host:$h_port/")->{success}, 'ua4 request');
	ok($ua5->get("http://$h_host:$h_port/")->{success}, 'ua5 request');
	
	kill 15, $s_pid4;
	ok(!$ua4->get("http://$h_host:$h_port/")->{success}, 'ua4 request -server4');
	ok($ua5->get("http://$h_host:$h_port/")->{success}, 'ua5 request -server4');
	
	kill 15, $s_pid5;
	ok(!$ua5->get("http://$h_host:$h_port/")->{success}, 'ua5 request -server5');
	
	kill 15, $h_pid;
};

done_testing;
