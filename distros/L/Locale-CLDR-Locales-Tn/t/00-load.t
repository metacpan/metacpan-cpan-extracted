#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Tn';
use ok 'Locale::CLDR::Locales::Tn::Latn::Bw';
use ok 'Locale::CLDR::Locales::Tn::Latn::Za';
use ok 'Locale::CLDR::Locales::Tn::Latn';

done_testing();
