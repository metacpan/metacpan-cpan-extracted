#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Gd';
use ok 'Locale::CLDR::Locales::Gd::Latn::Gb';
use ok 'Locale::CLDR::Locales::Gd::Latn';

done_testing();
