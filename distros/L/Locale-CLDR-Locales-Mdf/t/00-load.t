#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Mdf';
use ok 'Locale::CLDR::Locales::Mdf::Cyrl::Ru';
use ok 'Locale::CLDR::Locales::Mdf::Cyrl';

done_testing();
