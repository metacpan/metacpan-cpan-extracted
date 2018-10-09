#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.33.1, Perl $], $^X" );
use ok Locale::CLDR::Locales::Xog, 'Can use locale file Locale::CLDR::Locales::Xog';
use ok Locale::CLDR::Locales::Xog::Any::Ug, 'Can use locale file Locale::CLDR::Locales::Xog::Any::Ug';
use ok Locale::CLDR::Locales::Xog::Any, 'Can use locale file Locale::CLDR::Locales::Xog::Any';

done_testing();
