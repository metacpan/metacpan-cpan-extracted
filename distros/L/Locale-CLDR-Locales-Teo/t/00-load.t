#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Teo';
use ok 'Locale::CLDR::Locales::Teo::Latn::Ke';
use ok 'Locale::CLDR::Locales::Teo::Latn::Ug';
use ok 'Locale::CLDR::Locales::Teo::Latn';

done_testing();
