#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.2, Perl $], $^X" );
use ok Locale::CLDR::Locales::Ru;
use ok Locale::CLDR::Locales::Ru::Any::By;
use ok Locale::CLDR::Locales::Ru::Any::Kg;
use ok Locale::CLDR::Locales::Ru::Any::Kz;
use ok Locale::CLDR::Locales::Ru::Any::Md;
use ok Locale::CLDR::Locales::Ru::Any::Ru;
use ok Locale::CLDR::Locales::Ru::Any::Ua;
use ok Locale::CLDR::Locales::Ru::Any;

done_testing();
