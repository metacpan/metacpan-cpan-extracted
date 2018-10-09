#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.33.1, Perl $], $^X" );
use ok Locale::CLDR::Locales::Wo, 'Can use locale file Locale::CLDR::Locales::Wo';
use ok Locale::CLDR::Locales::Wo::Any::Sn, 'Can use locale file Locale::CLDR::Locales::Wo::Any::Sn';
use ok Locale::CLDR::Locales::Wo::Any, 'Can use locale file Locale::CLDR::Locales::Wo::Any';

done_testing();
