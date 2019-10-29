#!perl -T

use 5.010001;
use strict;
use warnings;

use Test::More tests => 2;

use HTML::Tidy5;
use HTML::Tidy5::Message;
use Test::HTML::Tidy5;

diag( "Testing HTML::Tidy5 $HTML::Tidy5::VERSION, tidy library version " . HTML::Tidy5->tidy_library_version() . ", Perl $], $^X" );

cmp_ok( HTML::Tidy5->tidy_library_version, 'ge', '5.6.0', 'HTML::Tidy5 requires version 5.6.0 or higher of the tidy-html5 library' );

is( $Test::HTML::Tidy5::VERSION, $HTML::Tidy5::VERSION, 'HTML::Tidy5 and Test::HTML::Tidy5 versions must match' );

exit 0;
