#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.32.0, Perl $], $^X" );
use ok Locale::CLDR::Locales::Dua, 'Can use locale file Locale::CLDR::Locales::Dua';
use ok Locale::CLDR::Locales::Dua::Any::Cm, 'Can use locale file Locale::CLDR::Locales::Dua::Any::Cm';
use ok Locale::CLDR::Locales::Dua::Any, 'Can use locale file Locale::CLDR::Locales::Dua::Any';

done_testing();
