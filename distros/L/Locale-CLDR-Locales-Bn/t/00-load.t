#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Bn';
use ok 'Locale::CLDR::Locales::Bn::Beng::Bd';
use ok 'Locale::CLDR::Locales::Bn::Beng::In';
use ok 'Locale::CLDR::Locales::Bn::Beng';

done_testing();
