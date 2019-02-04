#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34, Perl $], $^X" );
use ok Locale::CLDR::Locales::Mi, 'Can use locale file Locale::CLDR::Locales::Mi';
use ok Locale::CLDR::Locales::Mi::Any::Nz, 'Can use locale file Locale::CLDR::Locales::Mi::Any::Nz';
use ok Locale::CLDR::Locales::Mi::Any, 'Can use locale file Locale::CLDR::Locales::Mi::Any';

done_testing();
