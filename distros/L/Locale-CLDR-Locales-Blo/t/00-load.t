#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Blo';
use ok 'Locale::CLDR::Locales::Blo::Latn::Bj';
use ok 'Locale::CLDR::Locales::Blo::Latn';

done_testing();
