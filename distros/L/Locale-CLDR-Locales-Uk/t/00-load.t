#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Uk';
use ok 'Locale::CLDR::Locales::Uk::Cyrl::Ua';
use ok 'Locale::CLDR::Locales::Uk::Cyrl';

done_testing();
