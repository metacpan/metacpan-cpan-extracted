#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.29.0, Perl 5.018002, D:\strawberry\perl\bin\perl.exe" );
use ok Locale::CLDR::Locales::Fy, 'Can use locale file Locale::CLDR::Locales::Fy';
use ok Locale::CLDR::Locales::Fy::Any::Nl, 'Can use locale file Locale::CLDR::Locales::Fy::Any::Nl';
use ok Locale::CLDR::Locales::Fy::Any, 'Can use locale file Locale::CLDR::Locales::Fy::Any';

done_testing();
