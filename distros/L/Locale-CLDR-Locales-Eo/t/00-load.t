#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Eo';
use ok 'Locale::CLDR::Locales::Eo::Latn::001';
use ok 'Locale::CLDR::Locales::Eo::Latn';

done_testing();
