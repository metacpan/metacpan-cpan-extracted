#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Rof';
use ok 'Locale::CLDR::Locales::Rof::Latn::Tz';
use ok 'Locale::CLDR::Locales::Rof::Latn';

done_testing();
