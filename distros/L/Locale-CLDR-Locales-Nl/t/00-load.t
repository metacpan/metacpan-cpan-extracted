#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.29.0, Perl 5.018002, D:\strawberry\perl\bin\perl.exe" );
use ok Locale::CLDR::Locales::Nl, 'Can use locale file Locale::CLDR::Locales::Nl';
use ok Locale::CLDR::Locales::Nl::Any::Aw, 'Can use locale file Locale::CLDR::Locales::Nl::Any::Aw';
use ok Locale::CLDR::Locales::Nl::Any::Be, 'Can use locale file Locale::CLDR::Locales::Nl::Any::Be';
use ok Locale::CLDR::Locales::Nl::Any::Bq, 'Can use locale file Locale::CLDR::Locales::Nl::Any::Bq';
use ok Locale::CLDR::Locales::Nl::Any::Cw, 'Can use locale file Locale::CLDR::Locales::Nl::Any::Cw';
use ok Locale::CLDR::Locales::Nl::Any::Nl, 'Can use locale file Locale::CLDR::Locales::Nl::Any::Nl';
use ok Locale::CLDR::Locales::Nl::Any::Sr, 'Can use locale file Locale::CLDR::Locales::Nl::Any::Sr';
use ok Locale::CLDR::Locales::Nl::Any::Sx, 'Can use locale file Locale::CLDR::Locales::Nl::Any::Sx';
use ok Locale::CLDR::Locales::Nl::Any, 'Can use locale file Locale::CLDR::Locales::Nl::Any';

done_testing();
