#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Rwk';
use ok 'Locale::CLDR::Locales::Rwk::Latn::Tz';
use ok 'Locale::CLDR::Locales::Rwk::Latn';

done_testing();
