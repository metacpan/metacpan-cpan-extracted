#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Dsb';
use ok 'Locale::CLDR::Locales::Dsb::Latn::De';
use ok 'Locale::CLDR::Locales::Dsb::Latn';

done_testing();
