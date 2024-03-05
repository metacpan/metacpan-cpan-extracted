#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::St';
use ok 'Locale::CLDR::Locales::St::Latn::Ls';
use ok 'Locale::CLDR::Locales::St::Latn::Za';
use ok 'Locale::CLDR::Locales::St::Latn';

done_testing();
