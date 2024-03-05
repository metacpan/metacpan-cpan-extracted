#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Ka';
use ok 'Locale::CLDR::Locales::Ka::Geor::Ge';
use ok 'Locale::CLDR::Locales::Ka::Geor';

done_testing();
