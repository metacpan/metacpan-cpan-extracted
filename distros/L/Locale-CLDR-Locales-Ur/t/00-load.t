#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Ur';
use ok 'Locale::CLDR::Locales::Ur::Arab::In';
use ok 'Locale::CLDR::Locales::Ur::Arab::Pk';
use ok 'Locale::CLDR::Locales::Ur::Arab';

done_testing();
