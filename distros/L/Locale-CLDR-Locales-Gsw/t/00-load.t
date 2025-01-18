#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Gsw';
use ok 'Locale::CLDR::Locales::Gsw::Latn::Ch';
use ok 'Locale::CLDR::Locales::Gsw::Latn::Fr';
use ok 'Locale::CLDR::Locales::Gsw::Latn::Li';
use ok 'Locale::CLDR::Locales::Gsw::Latn';

done_testing();
