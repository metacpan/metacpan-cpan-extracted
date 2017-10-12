#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use HTTP::Tiny;

use_ok 'HTTP::Tiny::FileProtocol';

diag "Testing HTTP::Tiny::FileProtocol version " . HTTP::Tiny::FileProtocol->VERSION();

my $http = HTTP::Tiny->new;
isa_ok $http, 'HTTP::Tiny';
can_ok $http, 'get';

done_testing();
