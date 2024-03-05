#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Ba';
use ok 'Locale::CLDR::Locales::Ba::Cyrl::Ru';
use ok 'Locale::CLDR::Locales::Ba::Cyrl';

done_testing();
