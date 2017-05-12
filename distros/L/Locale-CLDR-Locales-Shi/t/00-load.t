#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.29.0, Perl 5.018002, D:\strawberry\perl\bin\perl.exe" );
use ok Locale::CLDR::Locales::Shi, 'Can use locale file Locale::CLDR::Locales::Shi';
use ok Locale::CLDR::Locales::Shi::Latn::Ma, 'Can use locale file Locale::CLDR::Locales::Shi::Latn::Ma';
use ok Locale::CLDR::Locales::Shi::Latn, 'Can use locale file Locale::CLDR::Locales::Shi::Latn';
use ok Locale::CLDR::Locales::Shi::Tfng::Ma, 'Can use locale file Locale::CLDR::Locales::Shi::Tfng::Ma';
use ok Locale::CLDR::Locales::Shi::Tfng, 'Can use locale file Locale::CLDR::Locales::Shi::Tfng';

done_testing();
