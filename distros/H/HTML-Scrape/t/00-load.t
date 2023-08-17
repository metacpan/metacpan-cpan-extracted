#!perl
use 5.10.1;
use strict;
use warnings;
use Test::More;

plan tests => 1;

use HTML::Scrape;

diag( "Testing HTML::Scrape $HTML::Scrape::VERSION, Perl $], $^X" );
pass();
