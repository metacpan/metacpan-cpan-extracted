#!perl

use warnings;
use strict;

use lib 't/lib';

use HTTP::AnyUA;
use Test::More tests => 3;

HTTP::AnyUA->register_backend(Mock => '+MockBackend');

my $any_ua  = HTTP::AnyUA->new(ua => 'Mock');
my $backend = $any_ua->backend;

$any_ua->apply_middleware('ContentLength');

my $url     = 'http://acme.tld/';
my $content = "hello world\n";

$any_ua->post($url, {content => $content});
my $cl = ($backend->requests)[-1][2]{headers}{'content-length'};
is $cl, length($content), 'content-length is set correctly with string content';

$any_ua->post($url);
$cl = ($backend->requests)[-1][2]{headers}{'content-length'};
is $cl, undef, 'content-length is not set with no content';

my $chunk   = 0;
my @chunk   = ('some ', 'document');
my $code    = sub { return $chunk[$chunk++] };

$any_ua->post($url, {content => $code});
$cl = ($backend->requests)[-1][2]{headers}{'content-length'};
is $cl, undef, 'content-length is not set with coderef content';

