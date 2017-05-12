#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use HTTP::Tiny;

use_ok 'HTTP::Tiny::Multipart';

my $http = HTTP::Tiny->new;
isa_ok $http, 'HTTP::Tiny';
can_ok $http, 'post_multipart';

done_testing();
