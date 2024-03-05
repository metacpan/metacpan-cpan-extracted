#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Yo';
use ok 'Locale::CLDR::Locales::Yo::Latn::Bj';
use ok 'Locale::CLDR::Locales::Yo::Latn::Ng';
use ok 'Locale::CLDR::Locales::Yo::Latn';

done_testing();
