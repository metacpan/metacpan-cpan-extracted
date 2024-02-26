#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::So';
use ok 'Locale::CLDR::Locales::So::Latn::Dj';
use ok 'Locale::CLDR::Locales::So::Latn::Et';
use ok 'Locale::CLDR::Locales::So::Latn::Ke';
use ok 'Locale::CLDR::Locales::So::Latn::So';
use ok 'Locale::CLDR::Locales::So::Latn';

done_testing();
