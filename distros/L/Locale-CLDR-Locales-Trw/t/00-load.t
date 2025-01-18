#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Trw';
use ok 'Locale::CLDR::Locales::Trw::Arab::Pk';
use ok 'Locale::CLDR::Locales::Trw::Arab';

done_testing();
