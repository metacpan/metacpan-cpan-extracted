#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use HTTP::Tiny::FileProtocol;

my $sub  = HTTP::Tiny::FileProtocol->can('_build_response');

my $url = 'file:///test.txt';

{
    is_deeply $sub->( $url, 1, 200, '', '', 'text/plain' ),
        {
            url     => $url,
            success => 1,
            status  => 200,
            content => '',
            headers => { 
                'content-type'   => 'text/plain',
                'content-length' => 0,
            }, 
        }
}

{
    is_deeply $sub->( $url, 1, 200, '', undef, 'text/plain' ),
        {
            url     => $url,
            success => 1,
            status  => 200,
            content => '',
            headers => { 
                'content-type'   => 'text/plain',
                'content-length' => 0,
            }, 
        }
}

{
    is_deeply $sub->( $url, 0, 200, 'Not found', 'test', 'text/plain' ),
        {
            url     => $url,
            success => 0,
            status  => 200,
            reason  => 'Not found',
            content => 'test',
            headers => { 
                'content-type'   => 'text/plain',
                'content-length' => 4,
            }, 
        }
}

done_testing();
