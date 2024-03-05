#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Lb';
use ok 'Locale::CLDR::Locales::Lb::Latn::Lu';
use ok 'Locale::CLDR::Locales::Lb::Latn';

done_testing();
