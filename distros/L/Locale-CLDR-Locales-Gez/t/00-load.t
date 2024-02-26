#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Gez';
use ok 'Locale::CLDR::Locales::Gez::Ethi::Er';
use ok 'Locale::CLDR::Locales::Gez::Ethi::Et';
use ok 'Locale::CLDR::Locales::Gez::Ethi';

done_testing();
