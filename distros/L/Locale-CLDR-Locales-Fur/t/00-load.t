#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.40.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Fur';
use ok 'Locale::CLDR::Locales::Fur::Any::It';
use ok 'Locale::CLDR::Locales::Fur::Any';

done_testing();
