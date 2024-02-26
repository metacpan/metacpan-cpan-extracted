#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Nr';
use ok 'Locale::CLDR::Locales::Nr::Latn::Za';
use ok 'Locale::CLDR::Locales::Nr::Latn';

done_testing();
