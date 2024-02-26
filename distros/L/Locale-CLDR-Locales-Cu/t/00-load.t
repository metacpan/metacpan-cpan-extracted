#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Cu';
use ok 'Locale::CLDR::Locales::Cu::Cyrl::Ru';
use ok 'Locale::CLDR::Locales::Cu::Cyrl';

done_testing();
