#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Sd';
use ok 'Locale::CLDR::Locales::Sd::Arab::Pk';
use ok 'Locale::CLDR::Locales::Sd::Arab';
use ok 'Locale::CLDR::Locales::Sd::Deva::In';
use ok 'Locale::CLDR::Locales::Sd::Deva';

done_testing();
