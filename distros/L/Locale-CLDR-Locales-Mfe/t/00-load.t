#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.29.0, Perl 5.018002, D:\strawberry\perl\bin\perl.exe" );
use ok Locale::CLDR::Locales::Mfe, 'Can use locale file Locale::CLDR::Locales::Mfe';
use ok Locale::CLDR::Locales::Mfe::Any::Mu, 'Can use locale file Locale::CLDR::Locales::Mfe::Any::Mu';
use ok Locale::CLDR::Locales::Mfe::Any, 'Can use locale file Locale::CLDR::Locales::Mfe::Any';

done_testing();
