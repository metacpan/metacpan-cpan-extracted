#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Ko';
use ok 'Locale::CLDR::Locales::Ko::Kore::Cn';
use ok 'Locale::CLDR::Locales::Ko::Kore::Kp';
use ok 'Locale::CLDR::Locales::Ko::Kore::Kr';
use ok 'Locale::CLDR::Locales::Ko::Kore';

done_testing();
