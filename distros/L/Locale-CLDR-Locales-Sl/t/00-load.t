#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.32.0, Perl $], $^X" );
use ok Locale::CLDR::Locales::Sl, 'Can use locale file Locale::CLDR::Locales::Sl';
use ok Locale::CLDR::Locales::Sl::Any::Si, 'Can use locale file Locale::CLDR::Locales::Sl::Any::Si';
use ok Locale::CLDR::Locales::Sl::Any, 'Can use locale file Locale::CLDR::Locales::Sl::Any';

done_testing();
