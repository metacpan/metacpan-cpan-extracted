#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34, Perl $], $^X" );
use ok Locale::CLDR::Locales::Mzn, 'Can use locale file Locale::CLDR::Locales::Mzn';
use ok Locale::CLDR::Locales::Mzn::Any::Ir, 'Can use locale file Locale::CLDR::Locales::Mzn::Any::Ir';
use ok Locale::CLDR::Locales::Mzn::Any, 'Can use locale file Locale::CLDR::Locales::Mzn::Any';

done_testing();
