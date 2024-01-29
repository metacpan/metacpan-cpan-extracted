#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.40.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Ksh';
use ok 'Locale::CLDR::Locales::Ksh::Any::De';
use ok 'Locale::CLDR::Locales::Ksh::Any';

done_testing();
