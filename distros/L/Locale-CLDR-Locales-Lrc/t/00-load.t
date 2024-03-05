#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Lrc';
use ok 'Locale::CLDR::Locales::Lrc::Arab::Iq';
use ok 'Locale::CLDR::Locales::Lrc::Arab::Ir';
use ok 'Locale::CLDR::Locales::Lrc::Arab';

done_testing();
