#!/usr/bin/env perl

use strict;
use Test::More;
use HTTP::Response;
use HTTP::Request;
use Digest::MD5;
use LWP::UserAgent::Cached;

eval {
	require File::Temp;
	File::Temp->import('tempdir');
};
if ($@) {
	plan skip_all => 'File::Temp not installed';
}

eval {
	require Test::Mock::LWP::Dispatch;
};
if ($@) {
	plan skip_all => 'Test::Mock::LWP::Dispatch not installed';
}

my $cache_dir = eval {
	tempdir(CLEANUP => 1)
};


unless ($cache_dir) {
	plan skip_all => "Сan't create temp dir";
}

my $ua = LWP::UserAgent::Cached->new(cache_dir => $cache_dir, cookie_jar => {});

# simple request test
my $mid = $ua->map('http://www.google.com/', HTTP::Response->new(200));
$ua->get('http://www.google.com/'); # cache 200 OK
$ua->unmap($mid);
$ua->map('http://www.google.com/', HTTP::Response->new(500));
is($ua->get('http://www.google.com/')->code, 200, 'Cached 200 ok response');

# more complex request test
my $response = HTTP::Response->new(301, 'Moved Permanently', [Location => 'http://www.yahoo.com/']);
$response->request(HTTP::Request->new(GET => 'http://yahoo.com'));
$mid = $ua->map('http://yahoo.com', $response);
my $y_mid = $ua->map('http://www.yahoo.com/', HTTP::Response->new(200, 'Ok', ['Set-Cookie' => 'lwp=true; cached=yes'], 'This is a test'));
$ua->get('http://yahoo.com'); # make cache
is(scalar($ua->last_cached), 2, '@last_cached length = 2 on redirect');
is(scalar($ua->last_used_cache), 2, '@last_used_cache length = 2 on redirect');
$ua->unmap($mid);
$ua->cookie_jar->clear();
my $resp = $ua->get('http://yahoo.com');
is($resp->code, 200, 'Cached response with redirect');
ok(index($resp->content, 'This is a test')!=-1, 'Cached response content') or diag "Content: ", $resp->content;
ok($ua->cookie_jar->as_string =~ /^(?=.*?lwp=true).*?cached=yes/, 'Cookies from the cache') or diag "Cookies: ", $ua->cookie_jar->as_string;
is(scalar($ua->last_cached), 0, '@last_cached length = 0 when get from cache');
is(scalar($ua->last_used_cache), 2, '@last_used_cache length = 2 when get from cache');

# nocache_if test
$ua->nocache_if(sub {
	$_[0]->code > 399
});
$mid = $ua->map('http://perl.org', HTTP::Response->new(403, 'Forbbidden'));
$ua->get('http://perl.org');
$ua->unmap($mid);
$ua->map('http://perl.org', HTTP::Response->new(200, 'OK', [], 'Perl there'));
$resp = $ua->get('http://perl.org');
is($resp->code, 200, 'Nocache code');
ok(index($resp->content, 'Perl there')!=-1, 'Nocache content') or diag 'Content: ', $resp->content;
$ua->nocache_if(undef);

# recache_if test
$ua->recache_if(sub {
	my ($resp, $path, $req) = @_;
	isa_ok($resp, 'HTTP::Response');
	isa_ok($req, 'HTTP::Request');
	ok(-e $path, 'Cached file exists') or diag "Path: $path";
	1;
});
$mid = $ua->map('http://perlmonks.org', HTTP::Response->new(407));
$ua->get('http://perlmonks.org');
$ua->unmap($mid);
$ua->map('http://perlmonks.org', HTTP::Response->new(200));
is($ua->get('http://perlmonks.org')->code, 200, 'Recached');
$ua->recache_if(undef);

# on_uncached test
$mid = $ua->map('http://www.modernperlbooks.com/', HTTP::Response->new(200));
my $on_uncached;
$ua->on_uncached(sub { $on_uncached = 1 });
$ua->get('http://www.modernperlbooks.com/');
is($on_uncached, 1, 'on_uncached called');
$on_uncached = undef;
$ua->get('http://www.modernperlbooks.com/');
is($on_uncached, undef, 'on_uncached not called');
$ua->on_uncached(undef);

# uncache test
$mid = $ua->map('http://metacpan.org', HTTP::Response->new(200));
$ua->get('http://metacpan.org');
$ua->uncache();
$ua->unmap($mid);
$ua->map('http://metacpan.org', HTTP::Response->new(503));
is($ua->get('http://metacpan.org')->code, 503, 'Uncache last response');

# collision test
$ua->cookie_jar->clear();
$resp = $ua->get('http://yahoo.com');
$ua->cookie_jar->clear();
my $cache_name = $ua->_get_cache_name($resp->request);
open FH, '>:raw', $cache_name;
print FH "http://google.com\nHTTP/1.1 200 OK\n";
close FH;
$ua->get('http://yahoo.com');
ok(-e "$cache_name-001", "Collision detected");

open FH, '>:raw', "$cache_name-001";
print FH "http://google.com\nHTTP/1.1 200 OK\n";
close FH;
$ua->cookie_jar->clear();
$ua->get('http://yahoo.com');
ok(-e "$cache_name-002", "Double collision detected");

$ua->unmap($y_mid);
$ua->map('http://www.yahoo.com/', HTTP::Response->new(404));
is($ua->get('http://yahoo.com')->code, 200, 'Cached response (collision list)');

# cache name specification test
$mid = $ua->map('http://perl.com', HTTP::Response->new(200));
$ua->agent('Internet-Explorer');
$ua->get('http://perl.com');
$ua->post('http://perl.com', ['q' => 'perl6', 'w' => 'now']);
$ua->unmap($mid);
$mid = $ua->map('http://perl.com', HTTP::Response->new(500));
$ua->cachename_spec({
	'User-Agent' => 'Internet-Explorer',
	'Accept' => undef
});
$ua->agent('Mozilla/5.0');
is($ua->get('http://perl.com', Accept => 'text/html')->code, 200, 'Cache name specification');

$ua->cachename_spec({
	_headers => ['User-Agent'],
	'User-Agent' => 'Internet-Explorer'
});
is($ua->get('http://perl.com', Accept => 'text/html')->code, 200, 'Cache name specification with _headers');

$ua->cachename_spec({
	_body => 'q=perl6&w=now',
	'User-Agent' => 'Internet-Explorer',
	'Content-Length' => 13,
});
is($ua->post('http://perl.com', ['q' => 'perl5', 'w' => 'yesterday'])->code, 200, 'Cache name specification with _body');

$mid = $ua->map('http://pause.perl.org', HTTP::Response->new(200));
$ua->cachename_spec({
	_body => '',
	_headers => []
});
$ua->post('http://pause.perl.org', [u => 'OLEG', act => 'login'], 'Accept' => 'text/html', 'Accept-Charset' => 'iso-8859');
$ua->unmap($mid);
$mid = $ua->map('http://pause.perl.org' => HTTP::Response->new(500));
$ua->agent('Google/Chrome');
is($ua->post('http://pause.perl.org', [u => 'UDGIN', act => 'logout'])->code, 200, 'Cache name based on url and http method');

done_testing;
