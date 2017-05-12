#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.29.0, Perl 5.018002, D:\strawberry\perl\bin\perl.exe" );
use ok Locale::CLDR::Locales::Uz, 'Can use locale file Locale::CLDR::Locales::Uz';
use ok Locale::CLDR::Locales::Uz::Arab::Af, 'Can use locale file Locale::CLDR::Locales::Uz::Arab::Af';
use ok Locale::CLDR::Locales::Uz::Arab, 'Can use locale file Locale::CLDR::Locales::Uz::Arab';
use ok Locale::CLDR::Locales::Uz::Cyrl::Uz, 'Can use locale file Locale::CLDR::Locales::Uz::Cyrl::Uz';
use ok Locale::CLDR::Locales::Uz::Cyrl, 'Can use locale file Locale::CLDR::Locales::Uz::Cyrl';
use ok Locale::CLDR::Locales::Uz::Latn::Uz, 'Can use locale file Locale::CLDR::Locales::Uz::Latn::Uz';
use ok Locale::CLDR::Locales::Uz::Latn, 'Can use locale file Locale::CLDR::Locales::Uz::Latn';

done_testing();
