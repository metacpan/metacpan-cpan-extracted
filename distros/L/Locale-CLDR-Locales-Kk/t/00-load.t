#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Kk';
use ok 'Locale::CLDR::Locales::Kk::Arab::Cn';
use ok 'Locale::CLDR::Locales::Kk::Arab';
use ok 'Locale::CLDR::Locales::Kk::Cyrl::Kz';
use ok 'Locale::CLDR::Locales::Kk::Cyrl';

done_testing();
