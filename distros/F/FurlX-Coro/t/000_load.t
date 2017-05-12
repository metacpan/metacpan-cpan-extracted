#!perl -w
use strict;
use Test::More tests => 1;

BEGIN {
    use_ok 'FurlX::Coro';
}

diag "Testing FurlX::Coro/$FurlX::Coro::VERSION";
