#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.33.0, Perl $], $^X" );
use ok Locale::CLDR::Locales::Kln, 'Can use locale file Locale::CLDR::Locales::Kln';
use ok Locale::CLDR::Locales::Kln::Any::Ke, 'Can use locale file Locale::CLDR::Locales::Kln::Any::Ke';
use ok Locale::CLDR::Locales::Kln::Any, 'Can use locale file Locale::CLDR::Locales::Kln::Any';

done_testing();
