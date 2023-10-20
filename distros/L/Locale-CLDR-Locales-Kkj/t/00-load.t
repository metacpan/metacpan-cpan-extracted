#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.2, Perl $], $^X" );
use ok Locale::CLDR::Locales::Kkj;
use ok Locale::CLDR::Locales::Kkj::Any::Cm;
use ok Locale::CLDR::Locales::Kkj::Any;

done_testing();
