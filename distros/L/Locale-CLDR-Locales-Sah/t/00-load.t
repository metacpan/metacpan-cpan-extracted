#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Sah';
use ok 'Locale::CLDR::Locales::Sah::Cyrl::Ru';
use ok 'Locale::CLDR::Locales::Sah::Cyrl';

done_testing();
