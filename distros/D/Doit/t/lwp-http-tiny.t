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

in_directory {
    my @ua_opts = (ua => $ua);

    is $doit->lwp_mirror("$httpbin_url/get",   "mirrored.txt", @ua_opts), 1, 'mirror was done';
    is $doit->lwp_mirror("$httpbin_url/cache", "mirrored.txt", @ua_opts), 0, 'no change';

    eval { $doit->lwp_mirror("$httpbin_url/status/500", "mirrored.txt", @ua_opts, debug => 1) };
    like $@, qr{ERROR.*mirroring failed: 500 };

} $tmpdir;

__END__
