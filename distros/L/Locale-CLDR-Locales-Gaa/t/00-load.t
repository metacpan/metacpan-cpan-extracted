#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Gaa';
use ok 'Locale::CLDR::Locales::Gaa::Latn::Gh';
use ok 'Locale::CLDR::Locales::Gaa::Latn';

done_testing();
