#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Ti';
use ok 'Locale::CLDR::Locales::Ti::Ethi::Er';
use ok 'Locale::CLDR::Locales::Ti::Ethi::Et';
use ok 'Locale::CLDR::Locales::Ti::Ethi';

done_testing();
