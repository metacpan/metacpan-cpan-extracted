#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Wa';
use ok 'Locale::CLDR::Locales::Wa::Latn::Be';
use ok 'Locale::CLDR::Locales::Wa::Latn';

done_testing();
