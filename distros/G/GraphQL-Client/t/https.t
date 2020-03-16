#!/usr/bin/env perl

use warnings;
use strict;

use Test::More;

use GraphQL::Client::https;

isa_ok('GraphQL::Client::https', 'GraphQL::Client::http');
can_ok('GraphQL::Client::https', qw(new execute));

done_testing;
