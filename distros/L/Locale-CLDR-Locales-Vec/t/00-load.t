#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Vec';
use ok 'Locale::CLDR::Locales::Vec::Latn::It';
use ok 'Locale::CLDR::Locales::Vec::Latn';

done_testing();
