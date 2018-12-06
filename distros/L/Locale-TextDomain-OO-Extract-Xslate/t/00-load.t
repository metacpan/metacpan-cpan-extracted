#!perl -T
# vim:syntax=perl:tabstop=4:number:noexpandtab:

use Test::More tests => 1;


BEGIN {
    use_ok( 'Locale::TextDomain::OO::Extract::Xslate' ) || print "Bail out!";
}

diag(
    "Testing Locale::TextDomain::OO::Extract::Xslate $Locale::TextDomain::OO::Extract::Xslate::VERSION, Perl $], $^X" );
