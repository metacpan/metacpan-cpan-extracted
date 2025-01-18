#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Ga';
use ok 'Locale::CLDR::Locales::Ga::Latn::Gb';
use ok 'Locale::CLDR::Locales::Ga::Latn::Ie';
use ok 'Locale::CLDR::Locales::Ga::Latn';

done_testing();
