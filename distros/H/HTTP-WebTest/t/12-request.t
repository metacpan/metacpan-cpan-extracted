#!/usr/bin/perl -w

# $Id: 12-request.t,v 1.6 2003/07/14 08:21:07 m_ilya Exp $

# Unit tests for HTTP::WebTest::Request

use strict;

use Test::More tests => 24;

use HTTP::WebTest::Request;

# test constructor
my $REQUEST;
{
    $REQUEST = HTTP::WebTest::Request->new;
    isa_ok($REQUEST, 'HTTP::WebTest::Request');
    isa_ok($REQUEST, 'HTTP::Request');
}

# test base_uri() and uri()
{
    for my $uri (qw(http://test1 http://a.a.a http://www.a.b)) {
	$REQUEST->base_uri($uri);
	is($REQUEST->base_uri, $uri);
	is($REQUEST->uri, $uri);
    }
}

# check that uri() returns URI object
{
    $REQUEST->base_uri('http://test2');
    my $uri = $REQUEST->uri;
    ok($uri->isa('URI'));
    is($uri->host, 'test2');
}

# check that alias url() work too
{
    $REQUEST->base_uri('http://test3');
    my $uri = $REQUEST->url;
    ok($uri->isa('URI'));
    is($uri->host, 'test3');
}

# set/get query params via params()
{
    # default value
    is(join(' ', @{$REQUEST->params}), '');

    $REQUEST->params([a => 'b']);
    is(join(' ', @{$REQUEST->params}), 'a b');

    $REQUEST->params([d => 'xy', 1 => 2]);
    is(join(' ', @{$REQUEST->params}), 'd xy 1 2');
}

# test setting uri via uri()
{
    $REQUEST->base_uri('http://a');
    $REQUEST->uri('http://b');
    is($REQUEST->uri, 'http://b');

    $REQUEST->uri('http://c?x=y');
    is($REQUEST->uri, 'http://c?x=y');
    is(join(' ', @{$REQUEST->params}), '');
}

# set some params and watch uri() to change for GET request
{
    $REQUEST->params([a => 'b']);
    $REQUEST->base_uri('http://a');
    $REQUEST->method('GET');
    is($REQUEST->uri, 'http://a?a=b');
    is(${$REQUEST->content_ref}, '');
}

# set some params and watch content_ref() to change for POST request
{
    $REQUEST->params([a => 'b']);
    $REQUEST->base_uri('http://a');
    $REQUEST->method('POST');
    is($REQUEST->uri, 'http://a');
    is(${$REQUEST->content_ref}, 'a=b');
}

# use array refs as param values and check if file upload request is
# created
{
    $REQUEST->params([a => ['t/12-request.t']]);
    $REQUEST->base_uri('http://a');
    $REQUEST->method('POST');
    is($REQUEST->uri, 'http://a');
    ok(${$REQUEST->content_ref} =~ 'Content-Disposition: form-data; name="a".*; filename="12-request.t');
}
