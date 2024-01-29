#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.40.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Sc';
use ok 'Locale::CLDR::Locales::Sc::Any::It';
use ok 'Locale::CLDR::Locales::Sc::Any';

done_testing();
