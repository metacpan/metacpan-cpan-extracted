#!perl -wT

use strict;
use warnings;
use Test::Most tests => 3;
use Lingua::String;

isa_ok(Lingua::String->new(), 'Lingua::String', 'Creating Lingua::String object');
isa_ok(Lingua::String->new()->new(), 'Lingua::String', 'Cloning Lingua::String object');
isa_ok(Lingua::String::new(), 'Lingua::String', 'Creating Lingua::String object');
