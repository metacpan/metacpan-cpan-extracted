#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.29.0, Perl 5.018002, D:\strawberry\perl\bin\perl.exe" );
use ok Locale::CLDR::Locales::Az, 'Can use locale file Locale::CLDR::Locales::Az';
use ok Locale::CLDR::Locales::Az::Cyrl::Az, 'Can use locale file Locale::CLDR::Locales::Az::Cyrl::Az';
use ok Locale::CLDR::Locales::Az::Cyrl, 'Can use locale file Locale::CLDR::Locales::Az::Cyrl';
use ok Locale::CLDR::Locales::Az::Latn::Az, 'Can use locale file Locale::CLDR::Locales::Az::Latn::Az';
use ok Locale::CLDR::Locales::Az::Latn, 'Can use locale file Locale::CLDR::Locales::Az::Latn';

done_testing();
