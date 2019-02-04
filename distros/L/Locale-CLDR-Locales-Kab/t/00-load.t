#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34, Perl $], $^X" );
use ok Locale::CLDR::Locales::Kab, 'Can use locale file Locale::CLDR::Locales::Kab';
use ok Locale::CLDR::Locales::Kab::Any::Dz, 'Can use locale file Locale::CLDR::Locales::Kab::Any::Dz';
use ok Locale::CLDR::Locales::Kab::Any, 'Can use locale file Locale::CLDR::Locales::Kab::Any';

done_testing();
