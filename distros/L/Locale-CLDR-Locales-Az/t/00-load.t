#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.4, Perl $], $^X" );
use ok Locale::CLDR::Locales::Az;
use ok Locale::CLDR::Locales::Az::Cyrl::Az;
use ok Locale::CLDR::Locales::Az::Cyrl;
use ok Locale::CLDR::Locales::Az::Latn::Az;
use ok Locale::CLDR::Locales::Az::Latn;

done_testing();
