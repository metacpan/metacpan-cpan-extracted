#!perl

use strict;
use warnings;

use Test::More;    # plan is down at bottom

use Lingua::Awkwords::String;

my $str = Lingua::Awkwords::String->new( string => 'asdf' );
is( $str->render, 'asdf' );

plan tests => 1;
