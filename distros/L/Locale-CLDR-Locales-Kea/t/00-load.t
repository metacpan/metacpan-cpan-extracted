#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Kea';
use ok 'Locale::CLDR::Locales::Kea::Latn::Cv';
use ok 'Locale::CLDR::Locales::Kea::Latn';

done_testing();
