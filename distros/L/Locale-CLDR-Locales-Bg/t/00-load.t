#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Bg';
use ok 'Locale::CLDR::Locales::Bg::Cyrl::Bg';
use ok 'Locale::CLDR::Locales::Bg::Cyrl';

done_testing();
