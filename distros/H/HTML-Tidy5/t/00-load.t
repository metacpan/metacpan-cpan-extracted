#!perl -T

use 5.010001;
use strict;
use warnings;

use Test::More tests => 1;

use HTML::Tidy5;
use HTML::Tidy5::Message;

pass( 'Modules loaded' );

diag( "Testing HTML::Tidy5 $HTML::Tidy5::VERSION, tidy " . HTML::Tidy5->tidy_library_version() . ", Perl $], $^X" );

exit 0;
