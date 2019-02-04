#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34, Perl $], $^X" );
use ok Locale::CLDR::Locales::Naq, 'Can use locale file Locale::CLDR::Locales::Naq';
use ok Locale::CLDR::Locales::Naq::Any::Na, 'Can use locale file Locale::CLDR::Locales::Naq::Any::Na';
use ok Locale::CLDR::Locales::Naq::Any, 'Can use locale file Locale::CLDR::Locales::Naq::Any';

done_testing();
