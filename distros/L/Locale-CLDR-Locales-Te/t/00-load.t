#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Te';
use ok 'Locale::CLDR::Locales::Te::Telu::In';
use ok 'Locale::CLDR::Locales::Te::Telu';

done_testing();
