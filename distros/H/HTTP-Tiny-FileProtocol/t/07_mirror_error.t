#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use HTTP::Tiny;

{
    no warnings 'redefine';
    sub HTTP::Tiny::mirror {
        'Test ;-)';
    }
}

use_ok 'HTTP::Tiny::FileProtocol';

my $http = HTTP::Tiny->new;
isa_ok $http, 'HTTP::Tiny';
can_ok $http, 'mirror';

is $http->mirror('http://test', 'filename'), 'Test ;-)';
is $http->mirror('http://test', 'filename', {}), 'Test ;-)';

done_testing();
