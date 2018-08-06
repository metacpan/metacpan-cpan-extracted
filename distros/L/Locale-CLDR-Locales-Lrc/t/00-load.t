#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.33.0, Perl $], $^X" );
use ok Locale::CLDR::Locales::Lrc, 'Can use locale file Locale::CLDR::Locales::Lrc';
use ok Locale::CLDR::Locales::Lrc::Any::Iq, 'Can use locale file Locale::CLDR::Locales::Lrc::Any::Iq';
use ok Locale::CLDR::Locales::Lrc::Any::Ir, 'Can use locale file Locale::CLDR::Locales::Lrc::Any::Ir';
use ok Locale::CLDR::Locales::Lrc::Any, 'Can use locale file Locale::CLDR::Locales::Lrc::Any';

done_testing();
