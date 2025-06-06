#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Csw';
use ok 'Locale::CLDR::Locales::Csw::Cans::Ca';
use ok 'Locale::CLDR::Locales::Csw::Cans';

done_testing();
