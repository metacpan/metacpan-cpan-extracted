#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Cs';
use ok 'Locale::CLDR::Locales::Cs::Latn::Cz';
use ok 'Locale::CLDR::Locales::Cs::Latn';

done_testing();
