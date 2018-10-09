#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.33.1, Perl $], $^X" );
use ok Locale::CLDR::Locales::Gu, 'Can use locale file Locale::CLDR::Locales::Gu';
use ok Locale::CLDR::Locales::Gu::Any::In, 'Can use locale file Locale::CLDR::Locales::Gu::Any::In';
use ok Locale::CLDR::Locales::Gu::Any, 'Can use locale file Locale::CLDR::Locales::Gu::Any';

done_testing();
