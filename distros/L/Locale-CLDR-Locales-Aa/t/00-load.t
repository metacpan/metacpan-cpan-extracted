#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Aa';
use ok 'Locale::CLDR::Locales::Aa::Latn::Dj';
use ok 'Locale::CLDR::Locales::Aa::Latn::Er';
use ok 'Locale::CLDR::Locales::Aa::Latn::Et';
use ok 'Locale::CLDR::Locales::Aa::Latn';

done_testing();
