#!/usr/bin/perl -w
# -*- cperl -*-

#
# Author: Slaven Rezic
#

use strict;
use File::Temp qw(tempdir);
use Test::More;

use Doit;
use Doit::Util qw(in_directory);

if (!eval { require HTTP::Tiny; 1 }) {
    plan skip_all => 'HTTP::Tiny not installed';
}

my $ua = HTTP::Tiny->new(timeout => 20);

#my $httpbin_url = 'https://httpbin.org';
my $httpbin_url = 'http://eu.httpbin.org';

{
    my $resp = $ua->get($httpbin_url);
    plan skip_all => "Cannot fetch successfully from $httpbin_url" if !$resp->{success};
}
    
plan 'no_plan';

my $doit = Doit->init;
$doit->add_component('lwp');

my $tmpdir = tempdir("doit-lwp-XXXXXXXX", CLEANUP => 1, TMPDIR => 1);

sub lwp_mirror_wrapper {
    my($url, $text, @more_ua_opts) = @_;
    my @ua_opts = (ua => $ua);
    my $res = eval { $doit->lwp_mirror($url, $text, @ua_opts, @more_ua_opts) };
    if ($@ && (
	       $@ =~ /503 Service Unavailable: Back-end server is at capacity/ ||
	       $@ =~ /599 Internal Exception: Timed out while waiting for socket to become ready for reading/
	      )) {
	skip "Unrecoverable backend error ($@), skipping remaining tests", 1;
    }
    ($res, $@);
}

in_directory {

 SKIP: {
	my($res, $err);

	($res, $err) = lwp_mirror_wrapper("$httpbin_url/get",   "mirrored.txt");
	is $res, 1, 'mirror was done';
	($res, $err) = lwp_mirror_wrapper("$httpbin_url/cache", "mirrored.txt");
	is $res, 0, 'no change';

	($res, $err) = lwp_mirror_wrapper("$httpbin_url/status/500", "mirrored.txt", debug => 1);
	like $err, qr{ERROR.*mirroring failed: 500 }, 'got status 500';

	($res, $err) = lwp_mirror_wrapper("unknown_scheme://localhost/foobar", "mirrored.txt", debug => 1);
	like $err, qr{ERROR.*mirroring failed: 599 Internal Exception: Unsupported URL scheme 'unknown_scheme}, 'got internal exception with extra information';
    }
} $tmpdir;

__END__
