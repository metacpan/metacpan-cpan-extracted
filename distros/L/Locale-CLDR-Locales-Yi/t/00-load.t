#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.40.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Yi';
use ok 'Locale::CLDR::Locales::Yi::Any::001';
use ok 'Locale::CLDR::Locales::Yi::Any';

done_testing();
