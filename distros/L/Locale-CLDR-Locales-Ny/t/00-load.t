#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Ny';
use ok 'Locale::CLDR::Locales::Ny::Latn::Mw';
use ok 'Locale::CLDR::Locales::Ny::Latn';

done_testing();
