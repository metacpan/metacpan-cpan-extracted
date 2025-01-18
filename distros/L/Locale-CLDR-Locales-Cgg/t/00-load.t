#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Cgg';
use ok 'Locale::CLDR::Locales::Cgg::Latn::Ug';
use ok 'Locale::CLDR::Locales::Cgg::Latn';

done_testing();
