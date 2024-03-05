#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Cad';
use ok 'Locale::CLDR::Locales::Cad::Latn::Us';
use ok 'Locale::CLDR::Locales::Cad::Latn';

done_testing();
