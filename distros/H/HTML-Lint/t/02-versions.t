#!perl -Tw

use warnings;
use strict;

use Test::More tests => 2;

use HTML::Lint::Parser;
use HTML::Lint;
use Test::HTML::Lint;

is( $HTML::Lint::VERSION, $Test::HTML::Lint::VERSION, 'HTML::Lint and Test::HTML::Lint versions match' );
is( $HTML::Lint::VERSION, $HTML::Lint::Parser::VERSION, 'HTML::Lint and Test::HTML::Lint versions match' );
