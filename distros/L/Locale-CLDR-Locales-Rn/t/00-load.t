#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.32.0, Perl $], $^X" );
use ok Locale::CLDR::Locales::Rn, 'Can use locale file Locale::CLDR::Locales::Rn';
use ok Locale::CLDR::Locales::Rn::Any::Bi, 'Can use locale file Locale::CLDR::Locales::Rn::Any::Bi';
use ok Locale::CLDR::Locales::Rn::Any, 'Can use locale file Locale::CLDR::Locales::Rn::Any';

done_testing();
