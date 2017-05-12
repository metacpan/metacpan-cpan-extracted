#!/usr/bin/env perl
use strict;
use warnings;
use FindBin qw/$Bin/;
use Test::More tests => 2;
use lib "$Bin/../lib";

BEGIN {
    use_ok('HTTP::Proxy::Selective') or BAIL_OUT($@);
}

my %fin = (
    'www.google.com' => { 
        'css' => '/my/own/css',
        'js'  => '/my/own/js',
        '/css/somewhere/here' => '/different/path',
    },
    'another.example.site' => {
        'hmmm2' => '/fnar',
        '/hmmm' => '/quux',
    }
    
);

my %fout = (
    'www.google.com' => [
        [ '/css/somewhere/here' => '/different/path' ],
        [ '/css'                => '/my/own/css'     ],
        [ '/js'                 => '/my/own/js'      ],
    ],
    'another.example.site' => [
           [ '/hmmm2' => '/fnar' ],
           [ '/hmmm' => '/quux'  ],
    ]
);

is_deeply(HTTP::Proxy::Selective::_generate_matches_from_config(%fin), \%fout, '_generate_matches_from_config transform ok');
