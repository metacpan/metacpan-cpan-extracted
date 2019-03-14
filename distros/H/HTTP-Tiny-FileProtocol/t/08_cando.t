#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use HTTP::Tiny;
use File::stat;

{
    no warnings 'redefine';
    sub File::stat::cando { return 0 };
}

use HTTP::Tiny::FileProtocol;

my $http = HTTP::Tiny->new;
isa_ok $http, 'HTTP::Tiny';
can_ok $http, 'get';

{
    my $response = $http->get('file://' . __FILE__ );
    delete $response->{url};
    is_deeply $response, {
        'status' => 403,
        'headers' => {
            'content-type' => 'text/plain',
            'content-length' => 0
        },
        'content' => '',
        'success' => undef,
        'reason' => 'Permission Denied',
    };
}

done_testing();
