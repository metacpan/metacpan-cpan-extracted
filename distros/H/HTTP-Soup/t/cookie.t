#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
use Data::Dumper;


BEGIN {
    use_ok('HTTP::Soup');
}

sub main {
    test_cookie();
    test_set_cookie();
    return 0;
}


sub test_cookie {
    my $cookie = HTTP::Soup::Cookie->new(
        'monster', 'blue',
        'sesame.com', '/here',
        10,
    );
    isa_ok($cookie, 'HTTP::Soup::Cookie');
    is($cookie->name, 'monster', "Name");
    is($cookie->value, 'blue', "Value");
    is($cookie->domain, 'sesame.com', "Domain");
    is($cookie->path, '/here', "Path");
    ok(!$cookie->http_only, "Http only");
    ok(!$cookie->secure, "Secure");
}


sub test_set_cookie {
    my $cookie = HTTP::Soup::Cookie->new(
        'monster', 'blue',
        'sesame.com', '/here',
        10,
    );
    isa_ok($cookie, 'HTTP::Soup::Cookie');
    
    $cookie->set_name('https');
    is($cookie->name, 'https', "Name");
    is($cookie->get_name, 'https', "Name (get)");

    $cookie->set_value('val');
    is($cookie->value, 'val', "Value");
    is($cookie->get_value, 'val', "Value (get)");

    $cookie->set_domain('dom');
    is($cookie->domain, 'dom', "Domain");
    is($cookie->get_domain, 'dom', "Domain (get)");

    $cookie->set_path('/path/deep');
    is($cookie->path, '/path/deep', "Path");
    is($cookie->get_path, '/path/deep', "Path (get)");

    $cookie->set_http_only(1);
    ok($cookie->http_only, "Http only");
    ok($cookie->get_http_only, "Http only (get)");

    $cookie->set_secure(1);
    ok($cookie->secure, "Secure");
    ok($cookie->get_secure, "Secure (get)");
}


exit main() unless caller;
