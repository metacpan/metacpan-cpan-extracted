#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Dz';
use ok 'Locale::CLDR::Locales::Dz::Tibt::Bt';
use ok 'Locale::CLDR::Locales::Dz::Tibt';

done_testing();
