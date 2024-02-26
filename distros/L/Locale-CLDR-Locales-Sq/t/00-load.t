#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Sq';
use ok 'Locale::CLDR::Locales::Sq::Latn::Al';
use ok 'Locale::CLDR::Locales::Sq::Latn::Mk';
use ok 'Locale::CLDR::Locales::Sq::Latn::Xk';
use ok 'Locale::CLDR::Locales::Sq::Latn';

done_testing();
