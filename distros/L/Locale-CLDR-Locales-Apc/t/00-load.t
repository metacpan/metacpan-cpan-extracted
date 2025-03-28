#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Apc';
use ok 'Locale::CLDR::Locales::Apc::Arab::Sy';
use ok 'Locale::CLDR::Locales::Apc::Arab';

done_testing();
