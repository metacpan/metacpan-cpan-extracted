#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Mzn';
use ok 'Locale::CLDR::Locales::Mzn::Arab::Ir';
use ok 'Locale::CLDR::Locales::Mzn::Arab';

done_testing();
