#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.29.0, Perl 5.018002, D:\strawberry\perl\bin\perl.exe" );
use ok Locale::CLDR::Locales::Tk, 'Can use locale file Locale::CLDR::Locales::Tk';
use ok Locale::CLDR::Locales::Tk::Any::Tm, 'Can use locale file Locale::CLDR::Locales::Tk::Any::Tm';
use ok Locale::CLDR::Locales::Tk::Any, 'Can use locale file Locale::CLDR::Locales::Tk::Any';

done_testing();
