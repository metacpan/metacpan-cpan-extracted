#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Mk';
use ok 'Locale::CLDR::Locales::Mk::Cyrl::Mk';
use ok 'Locale::CLDR::Locales::Mk::Cyrl';

done_testing();
