#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Tt';
use ok 'Locale::CLDR::Locales::Tt::Cyrl::Ru';
use ok 'Locale::CLDR::Locales::Tt::Cyrl';

done_testing();
