#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Warnings;

BEGIN {
    use_ok( 'File::TypeCategories' );
}

diag( "Testing File::TypeCategories $File::TypeCategories::VERSION, Perl $], $^X" );
done_testing();
