#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;


plan tests => 1;

BEGIN {
    use_ok( 'Email::IsEmail' ) || print "Bail out!\n";
}

diag( "Testing Email::IsEmail $Email::IsEmail::VERSION, Perl $], $^X" );
