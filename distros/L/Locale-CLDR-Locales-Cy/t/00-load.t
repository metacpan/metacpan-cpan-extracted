#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Cy';
use ok 'Locale::CLDR::Locales::Cy::Latn::Gb';
use ok 'Locale::CLDR::Locales::Cy::Latn';

done_testing();
