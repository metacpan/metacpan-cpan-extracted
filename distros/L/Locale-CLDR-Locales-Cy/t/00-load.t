#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.33.0, Perl $], $^X" );
use ok Locale::CLDR::Locales::Cy, 'Can use locale file Locale::CLDR::Locales::Cy';
use ok Locale::CLDR::Locales::Cy::Any::Gb, 'Can use locale file Locale::CLDR::Locales::Cy::Any::Gb';
use ok Locale::CLDR::Locales::Cy::Any, 'Can use locale file Locale::CLDR::Locales::Cy::Any';

done_testing();
