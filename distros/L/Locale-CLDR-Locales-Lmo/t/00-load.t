#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Lmo';
use ok 'Locale::CLDR::Locales::Lmo::Latn::It';
use ok 'Locale::CLDR::Locales::Lmo::Latn';

done_testing();
