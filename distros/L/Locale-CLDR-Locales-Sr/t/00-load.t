#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.4, Perl $], $^X" );
use ok Locale::CLDR::Locales::Sr;
use ok Locale::CLDR::Locales::Sr::Cyrl::Ba;
use ok Locale::CLDR::Locales::Sr::Cyrl::Me;
use ok Locale::CLDR::Locales::Sr::Cyrl::Rs;
use ok Locale::CLDR::Locales::Sr::Cyrl::Xk;
use ok Locale::CLDR::Locales::Sr::Cyrl;
use ok Locale::CLDR::Locales::Sr::Latn::Ba;
use ok Locale::CLDR::Locales::Sr::Latn::Me;
use ok Locale::CLDR::Locales::Sr::Latn::Rs;
use ok Locale::CLDR::Locales::Sr::Latn::Xk;
use ok Locale::CLDR::Locales::Sr::Latn;

done_testing();
