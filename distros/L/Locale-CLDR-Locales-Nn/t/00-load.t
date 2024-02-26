#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Nn';
use ok 'Locale::CLDR::Locales::Nn::Latn::No';
use ok 'Locale::CLDR::Locales::Nn::Latn';

done_testing();
