#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Tr';
use ok 'Locale::CLDR::Locales::Tr::Latn::Cy';
use ok 'Locale::CLDR::Locales::Tr::Latn::Tr';
use ok 'Locale::CLDR::Locales::Tr::Latn';

done_testing();
