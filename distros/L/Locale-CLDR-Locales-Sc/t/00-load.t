#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Sc';
use ok 'Locale::CLDR::Locales::Sc::Latn::It';
use ok 'Locale::CLDR::Locales::Sc::Latn';

done_testing();
