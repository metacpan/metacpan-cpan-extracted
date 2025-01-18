#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Eu';
use ok 'Locale::CLDR::Locales::Eu::Latn::Es';
use ok 'Locale::CLDR::Locales::Eu::Latn';

done_testing();
