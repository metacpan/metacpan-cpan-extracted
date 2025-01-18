#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Kam';
use ok 'Locale::CLDR::Locales::Kam::Latn::Ke';
use ok 'Locale::CLDR::Locales::Kam::Latn';

done_testing();
