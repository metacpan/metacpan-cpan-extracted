#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Af';
use ok 'Locale::CLDR::Locales::Af::Latn::Na';
use ok 'Locale::CLDR::Locales::Af::Latn::Za';
use ok 'Locale::CLDR::Locales::Af::Latn';

done_testing();
