#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Cic';
use ok 'Locale::CLDR::Locales::Cic::Latn::Us';
use ok 'Locale::CLDR::Locales::Cic::Latn';

done_testing();
