#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Elastijk;

my $request_content;

no warnings 'redefine';
sub Hijk::request {
    $request_content = $_[0];
    return { status => 200, body => "" }
}
use warnings;

subtest "The request structure for single-document APIs" => sub {
    my $es = Elastijk->new( host => "es.example.com", port => 9200 );

    $es->get(index => "foo", type => "bar", id => "kk");
    is_deeply( $request_content, {
        host => "es.example.com",
        port => 9200,
        method => "GET",
        path  => "/foo/bar/kk",
        head => [ 'Content-Type' => 'application/json' ]
    });

    $es->delete(index => "foo", type => "bar", id => "kk");
    is_deeply( $request_content, {
        host => "es.example.com",
        port => 9200,
        method => "DELETE",
        path  => "/foo/bar/kk",
        head => [ 'Content-Type' => 'application/json' ],
    });

    $es->index(index => "foo", type => "bar", id => "kk", body => { z => 1 });
    is_deeply( $request_content, {
        host => "es.example.com",
        port => 9200,
        method => "PUT",
        path  => "/foo/bar/kk",
        body => '{"z":1}',
        head => [ 'Content-Type' => 'application/json' ],
    });

};


subtest "The request structure for _search command" => sub {
    my $es = Elastijk->new( host => "es.example.com", port => 9200 );
    my $q = { query => { match_all => {} } };
    my $q_json = $Elastijk::JSON->encode($q);

    $es->search(index => "foo", type => "bar", body => $q);
    is_deeply( $request_content, {
        host => "es.example.com",
        port => 9200,
        method => "GET",
        path  => "/foo/bar/_search",
        body  => $q_json,
        head => [ 'Content-Type' => 'application/json' ],
    });

    $es->search(body => $q);
    is_deeply( $request_content, {
        host => "es.example.com",
        port => 9200,
        method => "GET",
        path  => "/_search",
        body  => $q_json,
        head => [ 'Content-Type' => 'application/json' ],
    });

    $es->search(index => "foo,baz", body => $q);
    is_deeply( $request_content, {
        host => "es.example.com",
        port => 9200,
        method => "GET",
        path  => '/foo%2Cbaz/_search',
        body  => $q_json,
        head => [ 'Content-Type' => 'application/json' ],
    });

    $es->search(index => "foo", uri_param => { q => "bar" });
    is_deeply( $request_content, {
        host => "es.example.com",
        port => 9200,
        method => "GET",
        path  => "/foo/_search",
        query_string => "q=bar",
        head => [ 'Content-Type' => 'application/json' ],
    });
};

subtest "{indices,type} exists api" => sub {
    my $es = Elastijk->new( host => "es.example.com", port => 9200 );
    $es->exists(index => "foo" );
    is_deeply( $request_content, {
        host => "es.example.com",
        port => 9200,
        method => "HEAD",
        path  => "/foo",
        head => [ 'Content-Type' => 'application/json' ],
    });

    $es->exists(index => "foo", type => "baz");
    is_deeply( $request_content, {
        host => "es.example.com",
        port => 9200,
        method => "HEAD",
        path  => "/foo/baz",
        head => [ 'Content-Type' => 'application/json' ],
    });

    # https://www.elastic.co/guide/guide/en/elasticsearch/guide/current/doc-exists.html#doc-exists
    $es->exists(index => "foo", type => "baz", id => 15);
    is_deeply( $request_content, {
        host => "es.example.com",
        port => 9200,
        method => "HEAD",
        path  => "/foo/baz/15",
        head => [ 'Content-Type' => 'application/json' ],
    });
};

subtest "{indices,type} exists api, with 'index' name coming from object." => sub {
    my $es = Elastijk->new( host => "es.example.com", port => 9200, index => "foo" );
    $es->exists();
    is_deeply( $request_content, {
        host => "es.example.com",
        port => 9200,
        method => "HEAD",
        path  => "/foo",
        head => [ 'Content-Type' => 'application/json' ],
    });

    $es->exists(type => "baz");
    is_deeply( $request_content, {
        host => "es.example.com",
        port => 9200,
        method => "HEAD",
        path  => "/foo/baz",
        head => [ 'Content-Type' => 'application/json' ],
    });

    # https://www.elastic.co/guide/guide/en/elasticsearch/guide/current/doc-exists.html#doc-exists
    $es->exists(type => "baz", id => 15);
    is_deeply( $request_content, {
        host => "es.example.com",
        port => 9200,
        method => "HEAD",
        path  => "/foo/baz/15",
        head => [ 'Content-Type' => 'application/json' ],
    });
};

done_testing;
