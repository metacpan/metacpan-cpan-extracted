#!perl -T

use Test::More tests => 1;

use HTML::Grabber;

ok(1, "Successfully loaded HTML::Grabber via 'use'");

diag( "Testing HTML::Grabber $HTML::Grabber::VERSION, Perl $], $^X" );
