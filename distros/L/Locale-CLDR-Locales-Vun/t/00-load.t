#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.32.0, Perl $], $^X" );
use ok Locale::CLDR::Locales::Vun, 'Can use locale file Locale::CLDR::Locales::Vun';
use ok Locale::CLDR::Locales::Vun::Any::Tz, 'Can use locale file Locale::CLDR::Locales::Vun::Any::Tz';
use ok Locale::CLDR::Locales::Vun::Any, 'Can use locale file Locale::CLDR::Locales::Vun::Any';

done_testing();
