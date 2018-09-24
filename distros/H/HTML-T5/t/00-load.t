#!perl -T

use 5.010001;
use strict;
use warnings;

use Test::More tests => 2;

use HTML::T5;
use HTML::T5::Message;
use Test::HTML::T5;

diag( "Testing HTML::T5 $HTML::T5::VERSION, tidy " . HTML::T5->tidy_library_version() . ", Perl $], $^X" );

cmp_ok( HTML::T5->tidy_library_version, 'ge', '5.6.0', 'HTML::T5 requires version 5.6.0 or higher of the tidy-html5 library' );

is( $Test::HTML::T5::VERSION, $HTML::T5::VERSION, 'HTML::T5 and Test::HTML::T5 versions must match' );

exit 0;
