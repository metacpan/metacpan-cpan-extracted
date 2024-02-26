#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Co';
use ok 'Locale::CLDR::Locales::Co::Latn::Fr';
use ok 'Locale::CLDR::Locales::Co::Latn';

done_testing();
