#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Wo';
use ok 'Locale::CLDR::Locales::Wo::Latn::Sn';
use ok 'Locale::CLDR::Locales::Wo::Latn';

done_testing();
