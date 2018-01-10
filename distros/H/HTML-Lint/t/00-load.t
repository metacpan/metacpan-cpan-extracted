#!perl -Tw

use strict;
use warnings;

use Test::More tests => 1;

use HTML::Lint;
use Test::HTML::Lint;

pass( 'Loaded modules' );
diag( "Testing HTML::Lint $HTML::Lint::VERSION, Perl $], $^X" );
