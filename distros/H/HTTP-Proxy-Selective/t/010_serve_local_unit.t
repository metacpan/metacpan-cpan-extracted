#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 14;
use Test::MockObject;

BEGIN { use_ok('HTTP::Proxy::Selective') or BAIL_OUT() };

my $mock_proxy = Test::MockObject->new;
my $mime_type;
$mock_proxy->mock('_mimetype' => sub { return $mime_type });
my $mock_headers = Test::MockObject->new;
my %headers;
$mock_headers->mock('header' => sub {
    my ( $self, $header_name ) = @_;
    return $headers{$header_name};
});
$mock_headers->mock('if_modified_since' => sub { 666; });
my $fake_stat = Test::MockObject->new;
my ($mtime, $size);
$fake_stat->mock('mtime' => sub { $mtime; });
$fake_stat->mock('size' => sub { $size; });
my ($stat_fn, $file_content);
{   no warnings 'redefine';
    *HTTP::Proxy::Selective::stat = sub ($) { $stat_fn = shift; return $fake_stat };
    $mock_proxy->mock('_mimetype' => sub { return $mime_type });
    *HTTP::Proxy::Selective::read_file = sub { return 'file contents' };
}
my $file_exists = 0;
{
    no warnings 'redefine';
    *HTTP::Proxy::Selective::__file_exists = sub { $file_exists };
}

{
    my $res = HTTP::Proxy::Selective::_serve_local($mock_proxy, $mock_headers, '/some/file');
    isa_ok($res, 'HTTP::Response');
    is($res->code, 404, 'Is a 404');
    is($res->header('Content-Type'), 'text/html', 'Content is text/html');
    ok($res->content =~ /Not found/, 'Content as expected (1/2)');
    ok($res->content =~ m|/some/file|, 'Content as expected (2/2)');
}

$file_exists = 1;
{
    $headers{'If-Modified-Since'} = 1;
    $mtime = 666; # == the header value..
    my $res = HTTP::Proxy::Selective::_serve_local($mock_proxy, $mock_headers, '/some/file');
    isa_ok($res, 'HTTP::Response');
    is($res->code, 304, 'Get 304 not modified');
    delete $headers{'If-Modified-Since'};
    $mtime = 999;
}

$mime_type = 'text/testmimetype';
$size = 5785673;
{
    no warnings 'redefine';
    my $res = HTTP::Proxy::Selective::_serve_local($mock_proxy, $mock_headers, '/some/file');
    isa_ok($res, 'HTTP::Response');
    is($res->code, 200, 'Is a 200 OK');
    is($res->headers->content_type, $mime_type);
    is($res->headers->content_length, $size);
    is($res->headers->last_modified, 999);
    is($res->content, 'file contents');
}
