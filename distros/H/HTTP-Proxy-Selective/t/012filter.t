#!/usr/bin/env perl
use strict;
use warnings;
use Test::MockObject;
use Test::More tests => 15;

BEGIN { use_ok('HTTP::Proxy::Selective') or BAIL_OUT() }

my $proxy = Test::MockObject->new;
my $response;
$proxy->mock( 'response' => sub { $_[1] ? $response = $_[1] : $response } );

my $self = Test::MockObject->new;
$self->mock( 'proxy'        => sub { $proxy } );
my ($serve_local_calls, $serve_local_ret, @serve_local_args) = (0);
$self->mock( '_serve_local' => sub { $serve_local_calls++; @serve_local_args = @_; return $serve_local_ret } );

my @filter_applies_args;
my $filter_applies_ret;
my $filter_applies_calls;
$self->mock( '_filter_applies' => sub { $filter_applies_calls++; @filter_applies_args = @_; return $filter_applies_ret });

my $headers = Test::MockObject->new;
my $uri     = Test::MockObject->new;
my ($host, $path, $path_called) = ('', '', 0);
$uri->mock( host => sub { $host } );
$uri->mock( path => sub { $path_called++; $path; });

my $message = Test::MockObject->new;
$message->mock( headers => sub { $headers } );
$message->mock( uri     => sub { $uri     } );

$self->{_myfilter} = {
    'www.google.com' => [
        [],
        [],
    ],
    'www.somesite.com' => [
        ['/', '/root-of-somesite']
    ],
    'another.test.site' => [
        ['/from/here/', '/to/here/'],
    ],
    'some.site' => [
        ['/path.jpg', '/my/path.jpg'],
    ],
};

$host = 'example.com';
HTTP::Proxy::Selective::filter($self, $headers, $message);
is($path_called, 0, 'No URL match returned early');

$host = 'www.google.com';
HTTP::Proxy::Selective::filter($self, $headers, $message);
is($path_called, 1, 'path called once');
is($filter_applies_calls, 2, 'Checked 2 filters for application');

$host = 'another.test.site';
$path = '/from/here/stuff.jpg';
HTTP::Proxy::Selective::filter($self, $headers, $message);
is($path_called, 2, 'Path called twice');
is($filter_applies_calls, 3, 'Checked 2 filters for application');
is_deeply(\@filter_applies_args, [$self, ['/from/here/', '/to/here/'], $path], '_filter_applies called with correct args');

$filter_applies_ret = 1;
$serve_local_ret = 'fnargle';
HTTP::Proxy::Selective::filter($self, $headers, $message);
is($path_called, 3, 'path called thrice');
is($filter_applies_calls, 4, 'Checked 4 filters for application');
is_deeply(\@filter_applies_args, [$self, ['/from/here/', '/to/here/'], $path], '_filter_applies called with correct args 2');
if($^O =~ /WIN32/i) {	
    is_deeply(\@serve_local_args, [$self, $headers, '\to\here\stuff.jpg'], '_serve_local args as expected');
}
else {
    is_deeply(\@serve_local_args, [$self, $headers, '/to/here/stuff.jpg'], '_serve_local args as expected');
}
is($serve_local_calls, 1, '_serve_local called once');
is($self->proxy->response, 'fnargle', 'Response from serve local pushed to proxy');

$host = 'some.site';
$path = '/path.jpg';
HTTP::Proxy::Selective::filter($self, $headers, $message);
is_deeply(\@filter_applies_args, [$self, ['/path.jpg', '/my/path.jpg'], $path], '_filter_applies called with correct args 3');
if($^O =~ /WIN32/i) {	
    is_deeply(\@serve_local_args, [$self, $headers, '\my\path.jpg'], '_serve_local args as expected');
}
else {
    is_deeply(\@serve_local_args, [$self, $headers, '/my/path.jpg'], '_serve_local args as expected');
}
