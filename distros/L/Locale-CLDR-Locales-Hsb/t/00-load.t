#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.40.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Hsb';
use ok 'Locale::CLDR::Locales::Hsb::Any::De';
use ok 'Locale::CLDR::Locales::Hsb::Any';

done_testing();
