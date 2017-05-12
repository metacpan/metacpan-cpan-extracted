#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.29.0, Perl 5.018002, D:\strawberry\perl\bin\perl.exe" );
use ok Locale::CLDR::Locales::Dua, 'Can use locale file Locale::CLDR::Locales::Dua';
use ok Locale::CLDR::Locales::Dua::Any::Cm, 'Can use locale file Locale::CLDR::Locales::Dua::Any::Cm';
use ok Locale::CLDR::Locales::Dua::Any, 'Can use locale file Locale::CLDR::Locales::Dua::Any';

done_testing();
