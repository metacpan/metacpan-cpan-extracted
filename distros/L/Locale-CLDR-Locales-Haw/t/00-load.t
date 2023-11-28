#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.3, Perl $], $^X" );
use ok Locale::CLDR::Locales::Haw;
use ok Locale::CLDR::Locales::Haw::Any::Us;
use ok Locale::CLDR::Locales::Haw::Any;

done_testing();
