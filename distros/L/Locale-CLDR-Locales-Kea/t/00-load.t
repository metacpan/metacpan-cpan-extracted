#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.40.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Kea';
use ok 'Locale::CLDR::Locales::Kea::Any::Cv';
use ok 'Locale::CLDR::Locales::Kea::Any';

done_testing();
