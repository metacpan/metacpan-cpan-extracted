#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.29.0, Perl 5.018002, D:\strawberry\perl\bin\perl.exe" );
use ok Locale::CLDR::Locales::Bs, 'Can use locale file Locale::CLDR::Locales::Bs';
use ok Locale::CLDR::Locales::Bs::Cyrl::Ba, 'Can use locale file Locale::CLDR::Locales::Bs::Cyrl::Ba';
use ok Locale::CLDR::Locales::Bs::Cyrl, 'Can use locale file Locale::CLDR::Locales::Bs::Cyrl';
use ok Locale::CLDR::Locales::Bs::Latn::Ba, 'Can use locale file Locale::CLDR::Locales::Bs::Latn::Ba';
use ok Locale::CLDR::Locales::Bs::Latn, 'Can use locale file Locale::CLDR::Locales::Bs::Latn';

done_testing();
