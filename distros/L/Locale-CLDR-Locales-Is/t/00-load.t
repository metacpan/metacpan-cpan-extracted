#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Is';
use ok 'Locale::CLDR::Locales::Is::Latn::Is';
use ok 'Locale::CLDR::Locales::Is::Latn';

done_testing();
