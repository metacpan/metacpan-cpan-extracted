#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Io';
use ok 'Locale::CLDR::Locales::Io::Latn::001';
use ok 'Locale::CLDR::Locales::Io::Latn';

done_testing();
