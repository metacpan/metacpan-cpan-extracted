#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Bo';
use ok 'Locale::CLDR::Locales::Bo::Tibt::Cn';
use ok 'Locale::CLDR::Locales::Bo::Tibt::In';
use ok 'Locale::CLDR::Locales::Bo::Tibt';

done_testing();
