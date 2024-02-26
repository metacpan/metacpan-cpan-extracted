#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Sl';
use ok 'Locale::CLDR::Locales::Sl::Latn::Si';
use ok 'Locale::CLDR::Locales::Sl::Latn';

done_testing();
