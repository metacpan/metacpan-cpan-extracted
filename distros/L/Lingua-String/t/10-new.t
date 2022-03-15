#!perl -wT

use strict;
use warnings;
use Test::Most tests => 2;
use Lingua::String;

isa_ok(Lingua::String->new(), 'Lingua::String', 'Creating Lingua::String object');
isa_ok(Lingua::String::new(), 'Lingua::String', 'Creating Lingua::String object');
