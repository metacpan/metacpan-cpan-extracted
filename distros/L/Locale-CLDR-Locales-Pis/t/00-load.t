#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Pis';
use ok 'Locale::CLDR::Locales::Pis::Latn::Sb';
use ok 'Locale::CLDR::Locales::Pis::Latn';

done_testing();
