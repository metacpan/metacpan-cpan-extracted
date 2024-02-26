#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Mic';
use ok 'Locale::CLDR::Locales::Mic::Latn::Ca';
use ok 'Locale::CLDR::Locales::Mic::Latn';

done_testing();
