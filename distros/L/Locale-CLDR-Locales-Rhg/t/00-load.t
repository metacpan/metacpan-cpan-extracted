#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Rhg';
use ok 'Locale::CLDR::Locales::Rhg::Rohg::Bd';
use ok 'Locale::CLDR::Locales::Rhg::Rohg::Mm';
use ok 'Locale::CLDR::Locales::Rhg::Rohg';

done_testing();
