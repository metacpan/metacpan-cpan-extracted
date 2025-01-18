#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Fil';
use ok 'Locale::CLDR::Locales::Fil::Latn::Ph';
use ok 'Locale::CLDR::Locales::Fil::Latn';

done_testing();
