#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Os';
use ok 'Locale::CLDR::Locales::Os::Cyrl::Ge';
use ok 'Locale::CLDR::Locales::Os::Cyrl::Ru';
use ok 'Locale::CLDR::Locales::Os::Cyrl';

done_testing();
