#!perl

use strict;
use warnings;

use Test::More;    # plan is down at bottom

use Lingua::Awkwords::ListOf;
use Lingua::Awkwords::String;

my @strings = map { Lingua::Awkwords::String->new( string => $_ ) } qw/foo bar/;

my $listof = Lingua::Awkwords::ListOf->new( terms => \@strings );
is( $listof->render, 'foobar' );

$listof->add( $strings[0] );
is( $listof->render, 'foobarfoo' );

$listof->add_filters('oo');
is( $listof->render, 'fbarf' );

$listof->add_filters( 'f', 'b' );
is( $listof->render, 'ar' );

$listof->filter_with('X');
is( $listof->render, 'XXXarXX' );

plan tests => 5;
