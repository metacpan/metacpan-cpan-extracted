#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Kw';
use ok 'Locale::CLDR::Locales::Kw::Latn::Gb';
use ok 'Locale::CLDR::Locales::Kw::Latn';

done_testing();
