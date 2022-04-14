#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.1, Perl $], $^X" );
use ok Locale::CLDR::Locales::Yue, 'Can use locale file Locale::CLDR::Locales::Yue';
use ok Locale::CLDR::Locales::Yue::Hant, 'Can use locale file Locale::CLDR::Locales::Yue::Hant';
use ok Locale::CLDR::Locales::Yue::Hans::Cn, 'Can use locale file Locale::CLDR::Locales::Yue::Hans::Cn';
use ok Locale::CLDR::Locales::Yue::Hant::Hk, 'Can use locale file Locale::CLDR::Locales::Yue::Hant::Hk';
use ok Locale::CLDR::Locales::Yue::Hans, 'Can use locale file Locale::CLDR::Locales::Yue::Hans';

done_testing();
