#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Khq';
use ok 'Locale::CLDR::Locales::Khq::Latn::Ml';
use ok 'Locale::CLDR::Locales::Khq::Latn';

done_testing();
