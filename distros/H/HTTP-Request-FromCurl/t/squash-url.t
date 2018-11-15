#!perl
use strict;
use HTTP::Request::FromCurl;
use URI;
use Test::More;
use Data::Dumper;

use Filter::signatures;
use feature 'signatures';
no warnings 'experimental::signatures';

my @tests = (
    [ 'https://example.com' => 'https://example.com/' ],
    [ 'https://example.com/././foo/..' => 'https://example.com/' ],
    [ 'https://example.com/././foo/./..' => 'https://example.com/' ],
    [ 'https://example.com/././foo/.' => 'https://example.com/foo/' ],
    [ 'https://example.com/foo/..' => 'https://example.com/' ],
    [ 'https://example.com/foo/../' => 'https://example.com/' ],
    [ 'https://example.com/foo/../..' => 'https://example.com/' ],
    [ 'https://example.com/foo/bar/baz/../..' => 'https://example.com/foo/' ],
    [ 'https://example.com/foo/bar/../baz/../' => 'https://example.com/foo/' ],
    [ 'https://example.com/foo/bar/../baz/../?batman=/foo/..' => 'https://example.com/foo/?batman=/foo/..' ],
);

plan tests => 0+@tests;

for my $test ( @tests ) {
    is( HTTP::Request::FromCurl->squash_uri( URI->new( $test->[0] )), URI->new( $test->[1] ), $test->[0] );
};

done_testing();
