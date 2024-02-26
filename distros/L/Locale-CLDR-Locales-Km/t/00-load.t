#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Km';
use ok 'Locale::CLDR::Locales::Km::Khmr::Kh';
use ok 'Locale::CLDR::Locales::Km::Khmr';

done_testing();
