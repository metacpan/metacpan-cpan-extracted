#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.4, Perl $], $^X" );
use ok Locale::CLDR::Locales::Fo;
use ok Locale::CLDR::Locales::Fo::Any::Dk;
use ok Locale::CLDR::Locales::Fo::Any::Fo;
use ok Locale::CLDR::Locales::Fo::Any;

done_testing();
