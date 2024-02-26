#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::As';
use ok 'Locale::CLDR::Locales::As::Beng::In';
use ok 'Locale::CLDR::Locales::As::Beng';

done_testing();
