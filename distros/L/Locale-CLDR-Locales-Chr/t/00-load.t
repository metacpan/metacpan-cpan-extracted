#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.29.0, Perl 5.018002, D:\strawberry\perl\bin\perl.exe" );
use ok Locale::CLDR::Locales::Chr, 'Can use locale file Locale::CLDR::Locales::Chr';
use ok Locale::CLDR::Locales::Chr::Any::Us, 'Can use locale file Locale::CLDR::Locales::Chr::Any::Us';
use ok Locale::CLDR::Locales::Chr::Any, 'Can use locale file Locale::CLDR::Locales::Chr::Any';

done_testing();
