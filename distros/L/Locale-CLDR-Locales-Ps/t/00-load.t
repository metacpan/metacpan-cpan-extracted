#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.40.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Ps';
use ok 'Locale::CLDR::Locales::Ps::Any::Af';
use ok 'Locale::CLDR::Locales::Ps::Any::Pk';
use ok 'Locale::CLDR::Locales::Ps::Any';

done_testing();
