#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Bal';
use ok 'Locale::CLDR::Locales::Bal::Arab::Pk';
use ok 'Locale::CLDR::Locales::Bal::Arab';
use ok 'Locale::CLDR::Locales::Bal::Latn::Pk';
use ok 'Locale::CLDR::Locales::Bal::Latn';

done_testing();
