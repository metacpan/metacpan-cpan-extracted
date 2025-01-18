#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::La';
use ok 'Locale::CLDR::Locales::La::Latn::Va';
use ok 'Locale::CLDR::Locales::La::Latn';

done_testing();
