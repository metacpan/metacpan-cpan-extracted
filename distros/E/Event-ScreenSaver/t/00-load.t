#!perl -T

use strict;
use warnings;
use Test::More;
use Test::Warnings;
use English qw/ -no_match_vars /;

BEGIN {
    use_ok( 'Event::ScreenSaver' );
    use_ok( 'Event::ScreenSaver::Unix' );
};

diag( "Testing Event::ScreenSaver $Event::ScreenSaver::VERSION, Perl $], $^X, $OSNAME" );
BAIL_OUT "Currently only support linux" if $OSNAME ne 'linux';
done_testing;
