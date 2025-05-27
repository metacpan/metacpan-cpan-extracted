#!perl -wT

use strict;
use warnings;
use Test::Most tests => 3;
use Lingua::Text;

isa_ok(Lingua::Text->new(), 'Lingua::Text', 'Creating Lingua::Text object');
isa_ok(Lingua::Text->new()->new(), 'Lingua::Text', 'Cloning Lingua::Text object');
isa_ok(Lingua::Text::new(), 'Lingua::Text', 'Creating Lingua::Text object');
