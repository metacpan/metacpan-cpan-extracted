#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Shn';
use ok 'Locale::CLDR::Locales::Shn::Mymr::Mm';
use ok 'Locale::CLDR::Locales::Shn::Mymr::Th';
use ok 'Locale::CLDR::Locales::Shn::Mymr';

done_testing();
