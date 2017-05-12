#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.29.0, Perl 5.018002, D:\strawberry\perl\bin\perl.exe" );
use ok Locale::CLDR::Locales::Mn, 'Can use locale file Locale::CLDR::Locales::Mn';
use ok Locale::CLDR::Locales::Mn::Any::Mn, 'Can use locale file Locale::CLDR::Locales::Mn::Any::Mn';
use ok Locale::CLDR::Locales::Mn::Any, 'Can use locale file Locale::CLDR::Locales::Mn::Any';

done_testing();
