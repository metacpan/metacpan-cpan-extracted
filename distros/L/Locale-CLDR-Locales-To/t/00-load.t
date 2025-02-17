#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::To';
use ok 'Locale::CLDR::Locales::To::Latn::To';
use ok 'Locale::CLDR::Locales::To::Latn';

done_testing();
