#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Syr';
use ok 'Locale::CLDR::Locales::Syr::Syrc::Iq';
use ok 'Locale::CLDR::Locales::Syr::Syrc::Sy';
use ok 'Locale::CLDR::Locales::Syr::Syrc';

done_testing();
