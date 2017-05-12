#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Warnings;

BEGIN {
    use_ok( 'Log::Deep'       );
    use_ok( 'Log::Deep::Read' );
    use_ok( 'Log::Deep::Line' );
    use_ok( 'Log::Deep::File' );
}

diag( "Testing Log::Deep $Log::Deep::VERSION, Perl $], $^X" );
done_testing();
