#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Nd';
use ok 'Locale::CLDR::Locales::Nd::Latn::Zw';
use ok 'Locale::CLDR::Locales::Nd::Latn';

done_testing();
