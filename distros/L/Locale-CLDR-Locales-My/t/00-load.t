#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.29.0, Perl 5.018002, D:\strawberry\perl\bin\perl.exe" );
use ok Locale::CLDR::Locales::My, 'Can use locale file Locale::CLDR::Locales::My';
use ok Locale::CLDR::Locales::My::Any::Mm, 'Can use locale file Locale::CLDR::Locales::My::Any::Mm';
use ok Locale::CLDR::Locales::My::Any, 'Can use locale file Locale::CLDR::Locales::My::Any';

done_testing();
