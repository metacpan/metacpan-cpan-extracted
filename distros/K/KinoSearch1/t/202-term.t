#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 3;
use List::Util qw( shuffle );

BEGIN { use_ok('KinoSearch1::Index::Term') }

my $foo_term = KinoSearch1::Index::Term->new( "f1", "foo" );
my $bar_term = KinoSearch1::Index::Term->new( "f3", "bar" );

is( $foo_term->get_text,  'foo', "get_text should return correct val" );
is( $bar_term->get_field, "f3",  "get_field should return correct val" );

