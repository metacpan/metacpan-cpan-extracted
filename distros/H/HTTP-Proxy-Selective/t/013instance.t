#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 3;

my $matches = {
    'www.google.com' => {
        '/css/somewhere/here' => '/different/path',
        '/css'                => '/my/own/css',
        '/js'                 => '/my/own/js',
    },
    'another.example.site' => {
           '/hmmm2' => '/fnar',
           '/hmmm'  => '/quux',
    }  
};

use_ok("HTTP::Proxy::Selective")or BAIL_OUT;
my $filter = eval { HTTP::Proxy::Selective->new($matches) };

ok($filter, 'Have a $filter') or BAIL_OUT($@);
ok(!$@, 'No exception');
