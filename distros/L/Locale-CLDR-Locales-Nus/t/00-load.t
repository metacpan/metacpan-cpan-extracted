#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Nus';
use ok 'Locale::CLDR::Locales::Nus::Latn::Ss';
use ok 'Locale::CLDR::Locales::Nus::Latn';

done_testing();
