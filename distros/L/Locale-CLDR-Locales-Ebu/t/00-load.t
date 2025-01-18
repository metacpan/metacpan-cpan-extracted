#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Ebu';
use ok 'Locale::CLDR::Locales::Ebu::Latn::Ke';
use ok 'Locale::CLDR::Locales::Ebu::Latn';

done_testing();
