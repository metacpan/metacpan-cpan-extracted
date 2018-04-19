#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.32.0, Perl $], $^X" );
use ok Locale::CLDR::Locales::Sn, 'Can use locale file Locale::CLDR::Locales::Sn';
use ok Locale::CLDR::Locales::Sn::Any::Zw, 'Can use locale file Locale::CLDR::Locales::Sn::Any::Zw';
use ok Locale::CLDR::Locales::Sn::Any, 'Can use locale file Locale::CLDR::Locales::Sn::Any';

done_testing();
