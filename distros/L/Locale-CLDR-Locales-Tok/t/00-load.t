#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Tok';
use ok 'Locale::CLDR::Locales::Tok::Latn::001';
use ok 'Locale::CLDR::Locales::Tok::Latn';

done_testing();
