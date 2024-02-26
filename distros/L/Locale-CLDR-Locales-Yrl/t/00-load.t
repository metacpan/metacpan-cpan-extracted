#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Yrl';
use ok 'Locale::CLDR::Locales::Yrl::Latn::Br';
use ok 'Locale::CLDR::Locales::Yrl::Latn::Co';
use ok 'Locale::CLDR::Locales::Yrl::Latn::Ve';
use ok 'Locale::CLDR::Locales::Yrl::Latn';

done_testing();
