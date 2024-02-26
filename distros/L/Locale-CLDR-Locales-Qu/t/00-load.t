#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Qu';
use ok 'Locale::CLDR::Locales::Qu::Latn::Bo';
use ok 'Locale::CLDR::Locales::Qu::Latn::Ec';
use ok 'Locale::CLDR::Locales::Qu::Latn::Pe';
use ok 'Locale::CLDR::Locales::Qu::Latn';

done_testing();
