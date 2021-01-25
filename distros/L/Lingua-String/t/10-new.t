#!perl -wT

use strict;

use lib 'lib';
use Test::Most tests => 2;
use Lingua::String;

isa_ok(Lingua::String->new(), 'Lingua::String', 'Creating Lingua::String object');
ok(!defined(Lingua::String::new()));
