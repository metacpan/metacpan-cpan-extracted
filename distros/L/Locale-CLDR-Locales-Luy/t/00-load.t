#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.33.0, Perl $], $^X" );
use ok Locale::CLDR::Locales::Luy, 'Can use locale file Locale::CLDR::Locales::Luy';
use ok Locale::CLDR::Locales::Luy::Any::Ke, 'Can use locale file Locale::CLDR::Locales::Luy::Any::Ke';
use ok Locale::CLDR::Locales::Luy::Any, 'Can use locale file Locale::CLDR::Locales::Luy::Any';

done_testing();
