#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Ks';
use ok 'Locale::CLDR::Locales::Ks::Arab::In';
use ok 'Locale::CLDR::Locales::Ks::Arab';
use ok 'Locale::CLDR::Locales::Ks::Deva::In';
use ok 'Locale::CLDR::Locales::Ks::Deva';

done_testing();
