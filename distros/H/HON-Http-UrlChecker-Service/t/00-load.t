#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'HON::Http::UrlChecker::Service' ) || print "Bail out!\n";
}

diag( "Testing HON::Http::UrlChecker::Service $HON::Http::UrlChecker::Service::VERSION, Perl $], $^X" );
