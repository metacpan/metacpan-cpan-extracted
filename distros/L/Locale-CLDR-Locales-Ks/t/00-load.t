#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.40.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Ks';
use ok 'Locale::CLDR::Locales::Ks::Arab::In';
use ok 'Locale::CLDR::Locales::Ks::Arab';

done_testing();
