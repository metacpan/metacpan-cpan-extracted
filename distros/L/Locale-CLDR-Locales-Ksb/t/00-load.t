#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Ksb';
use ok 'Locale::CLDR::Locales::Ksb::Latn::Tz';
use ok 'Locale::CLDR::Locales::Ksb::Latn';

done_testing();
