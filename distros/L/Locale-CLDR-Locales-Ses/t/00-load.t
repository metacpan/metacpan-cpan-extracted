#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Ses';
use ok 'Locale::CLDR::Locales::Ses::Latn::Ml';
use ok 'Locale::CLDR::Locales::Ses::Latn';

done_testing();
