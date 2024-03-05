#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Tpi';
use ok 'Locale::CLDR::Locales::Tpi::Latn::Pg';
use ok 'Locale::CLDR::Locales::Tpi::Latn';

done_testing();
