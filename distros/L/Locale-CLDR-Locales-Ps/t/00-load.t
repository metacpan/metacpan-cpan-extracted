#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Ps';
use ok 'Locale::CLDR::Locales::Ps::Arab::Af';
use ok 'Locale::CLDR::Locales::Ps::Arab::Pk';
use ok 'Locale::CLDR::Locales::Ps::Arab';

done_testing();
