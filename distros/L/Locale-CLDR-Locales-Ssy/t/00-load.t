#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Ssy';
use ok 'Locale::CLDR::Locales::Ssy::Latn::Er';
use ok 'Locale::CLDR::Locales::Ssy::Latn';

done_testing();
