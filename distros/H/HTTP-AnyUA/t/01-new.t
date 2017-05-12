#!perl

use warnings;
use strict;

use lib 't/lib';

use HTTP::AnyUA;
use Test::Exception;
use Test::More tests => 3;

my $any_ua1 = HTTP::AnyUA->new(ua => 'Mock');
ok $any_ua1, 'can construct a new HTTP::AnyUA';

my $any_ua2 = HTTP::AnyUA->new('Mock');
ok $any_ua2, 'can construct a new HTTP::AnyUA';

throws_ok { HTTP::AnyUA->new() } qr/^Usage:/, 'constructor requires user agent';

