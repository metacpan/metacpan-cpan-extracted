#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.4, Perl $], $^X" );
use ok Locale::CLDR::Locales::Dje;
use ok Locale::CLDR::Locales::Dje::Any::Ne;
use ok Locale::CLDR::Locales::Dje::Any;

done_testing();
