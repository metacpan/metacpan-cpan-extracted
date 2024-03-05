#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Lg';
use ok 'Locale::CLDR::Locales::Lg::Latn::Ug';
use ok 'Locale::CLDR::Locales::Lg::Latn';

done_testing();
