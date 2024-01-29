#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.40.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Yrl';
use ok 'Locale::CLDR::Locales::Yrl::Any::Br';
use ok 'Locale::CLDR::Locales::Yrl::Any::Co';
use ok 'Locale::CLDR::Locales::Yrl::Any::Ve';
use ok 'Locale::CLDR::Locales::Yrl::Any';

done_testing();
