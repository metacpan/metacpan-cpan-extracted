#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Br';
use ok 'Locale::CLDR::Locales::Br::Latn::Fr';
use ok 'Locale::CLDR::Locales::Br::Latn';

done_testing();
