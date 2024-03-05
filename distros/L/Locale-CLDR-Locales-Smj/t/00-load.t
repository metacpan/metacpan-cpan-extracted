#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Smj';
use ok 'Locale::CLDR::Locales::Smj::Latn::No';
use ok 'Locale::CLDR::Locales::Smj::Latn::Se';
use ok 'Locale::CLDR::Locales::Smj::Latn';

done_testing();
