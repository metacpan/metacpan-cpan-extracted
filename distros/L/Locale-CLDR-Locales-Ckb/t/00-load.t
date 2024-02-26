#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Ckb';
use ok 'Locale::CLDR::Locales::Ckb::Arab::Iq';
use ok 'Locale::CLDR::Locales::Ckb::Arab::Ir';
use ok 'Locale::CLDR::Locales::Ckb::Arab';

done_testing();
