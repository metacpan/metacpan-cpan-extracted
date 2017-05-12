#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
use Data::Dumper;


BEGIN {
    use_ok('HTTP::Soup');
}

sub main {
    test_uri();
    test_set_uri();
    return 0;
}


sub test_uri {
    my $uri = HTTP::Soup::URI->new('httPs://uzer:passw@host/path/deep?query=2+3&args=%58#go-to');
    isa_ok($uri, 'HTTP::Soup::URI');
    is($uri->scheme, 'https', "Scheme");
    is($uri->user, 'uzer', "User");
    is($uri->password, 'passw', "Password");
    is($uri->host, 'host', "Host");
    is($uri->path, '/path/deep', "Path");
    is($uri->query, 'query=2+3&args=X', "Query");
    is($uri->fragment, 'go-to', "Fragment");
}


sub test_set_uri {
    my $uri = HTTP::Soup::URI->new('http://localhost/here');
    isa_ok($uri, 'HTTP::Soup::URI');
    
    $uri->set_scheme('https');
    is($uri->scheme, 'https', "Scheme");
    is($uri->get_scheme, 'https', "Scheme (get)");

    $uri->set_user('uzer');
    is($uri->user, 'uzer', "User");
    is($uri->get_user, 'uzer', "User (get)");

    $uri->set_password('passw');
    is($uri->password, 'passw', "Password");
    is($uri->get_password, 'passw', "Password (get)");

    $uri->set_host('host');
    is($uri->host, 'host', "Host");
    is($uri->get_host, 'host', "Host (get)");

    $uri->set_path('/path/deep');
    is($uri->path, '/path/deep', "Path");
    is($uri->get_path, '/path/deep', "Path (get)");

    $uri->set_query('query=2+3&args=%58');
    is($uri->query, 'query=2+3&args=%58', "Query");
    is($uri->get_query, 'query=2+3&args=%58', "Query (get)");

    $uri->set_fragment('go-to');
    is($uri->fragment, 'go-to', "Fragment");
    is($uri->get_fragment, 'go-to', "Fragment (get)");

    is($uri->to_string(0), 'https://uzer@host/path/deep?query=2+3&args=%58#go-to', "to string");
    ok($uri->uses_default_port, "uses_default_port");

    $uri->set_port(99);
    is($uri->port, '99', "Port");
    is($uri->get_port, '99', "Port (get)");
    ok(!$uri->uses_default_port, "uses_default_port");
}


exit main() unless caller;
