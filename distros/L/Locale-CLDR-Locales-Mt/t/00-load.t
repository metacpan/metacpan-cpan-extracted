#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34, Perl $], $^X" );
use ok Locale::CLDR::Locales::Mt, 'Can use locale file Locale::CLDR::Locales::Mt';
use ok Locale::CLDR::Locales::Mt::Any::Mt, 'Can use locale file Locale::CLDR::Locales::Mt::Any::Mt';
use ok Locale::CLDR::Locales::Mt::Any, 'Can use locale file Locale::CLDR::Locales::Mt::Any';

done_testing();
