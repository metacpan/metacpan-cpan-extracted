#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Tzm';
use ok 'Locale::CLDR::Locales::Tzm::Latn::Ma';
use ok 'Locale::CLDR::Locales::Tzm::Latn';

done_testing();
