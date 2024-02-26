#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Bm';
use ok 'Locale::CLDR::Locales::Bm::Latn::Ml';
use ok 'Locale::CLDR::Locales::Bm::Latn';
use ok 'Locale::CLDR::Locales::Bm::Nkoo::Ml';
use ok 'Locale::CLDR::Locales::Bm::Nkoo';

done_testing();
