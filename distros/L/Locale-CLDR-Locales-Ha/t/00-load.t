#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.3, Perl $], $^X" );
use ok Locale::CLDR::Locales::Ha;
use ok Locale::CLDR::Locales::Ha::Any::Gh;
use ok Locale::CLDR::Locales::Ha::Any::Ne;
use ok Locale::CLDR::Locales::Ha::Any::Ng;
use ok Locale::CLDR::Locales::Ha::Any;

done_testing();
