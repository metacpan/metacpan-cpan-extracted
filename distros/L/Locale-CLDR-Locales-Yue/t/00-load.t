#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Yue';
use ok 'Locale::CLDR::Locales::Yue::Hans::Cn';
use ok 'Locale::CLDR::Locales::Yue::Hans';
use ok 'Locale::CLDR::Locales::Yue::Hant::Cn';
use ok 'Locale::CLDR::Locales::Yue::Hant::Hk';
use ok 'Locale::CLDR::Locales::Yue::Hant';

done_testing();
