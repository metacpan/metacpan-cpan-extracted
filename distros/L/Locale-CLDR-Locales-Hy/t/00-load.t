#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.29.0, Perl 5.018002, D:\strawberry\perl\bin\perl.exe" );
use ok Locale::CLDR::Locales::Hy, 'Can use locale file Locale::CLDR::Locales::Hy';
use ok Locale::CLDR::Locales::Hy::Any::Am, 'Can use locale file Locale::CLDR::Locales::Hy::Any::Am';
use ok Locale::CLDR::Locales::Hy::Any, 'Can use locale file Locale::CLDR::Locales::Hy::Any';

done_testing();
