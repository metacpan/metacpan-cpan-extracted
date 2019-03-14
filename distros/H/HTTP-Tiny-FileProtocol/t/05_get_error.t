#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use HTTP::Tiny;

{
    no warnings 'redefine';
    sub HTTP::Tiny::get {
        'Test ;-)';
    }
}

use_ok 'HTTP::Tiny::FileProtocol';

my $http = HTTP::Tiny->new;
isa_ok $http, 'HTTP::Tiny';
can_ok $http, 'get';

is $http->get('http://test'), 'Test ;-)';
is $http->get('http://test', {} ), 'Test ;-)';

done_testing();
