#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Sw';
use ok 'Locale::CLDR::Locales::Sw::Latn::Cd';
use ok 'Locale::CLDR::Locales::Sw::Latn::Ke';
use ok 'Locale::CLDR::Locales::Sw::Latn::Tz';
use ok 'Locale::CLDR::Locales::Sw::Latn::Ug';
use ok 'Locale::CLDR::Locales::Sw::Latn';

done_testing();
