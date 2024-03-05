#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Sid';
use ok 'Locale::CLDR::Locales::Sid::Latn::Et';
use ok 'Locale::CLDR::Locales::Sid::Latn';

done_testing();
