#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Ts';
use ok 'Locale::CLDR::Locales::Ts::Latn::Za';
use ok 'Locale::CLDR::Locales::Ts::Latn';

done_testing();
