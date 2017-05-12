#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.29.0, Perl 5.018002, D:\strawberry\perl\bin\perl.exe" );
use ok Locale::CLDR::Locales::Rn, 'Can use locale file Locale::CLDR::Locales::Rn';
use ok Locale::CLDR::Locales::Rn::Any::Bi, 'Can use locale file Locale::CLDR::Locales::Rn::Any::Bi';
use ok Locale::CLDR::Locales::Rn::Any, 'Can use locale file Locale::CLDR::Locales::Rn::Any';

done_testing();
