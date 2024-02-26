#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Or';
use ok 'Locale::CLDR::Locales::Or::Orya::In';
use ok 'Locale::CLDR::Locales::Or::Orya';

done_testing();
