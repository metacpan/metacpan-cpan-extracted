#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Ab';
use ok 'Locale::CLDR::Locales::Ab::Cyrl::Ge';
use ok 'Locale::CLDR::Locales::Ab::Cyrl';

done_testing();
