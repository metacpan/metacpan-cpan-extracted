#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.40.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Lv';
use ok 'Locale::CLDR::Locales::Lv::Any::Lv';
use ok 'Locale::CLDR::Locales::Lv::Any';

done_testing();
