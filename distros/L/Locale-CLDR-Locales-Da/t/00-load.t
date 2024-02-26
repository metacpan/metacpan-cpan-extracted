#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Da';
use ok 'Locale::CLDR::Locales::Da::Latn::Dk';
use ok 'Locale::CLDR::Locales::Da::Latn::Gl';
use ok 'Locale::CLDR::Locales::Da::Latn';

done_testing();
