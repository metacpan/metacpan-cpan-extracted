#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Scn';
use ok 'Locale::CLDR::Locales::Scn::Latn::It';
use ok 'Locale::CLDR::Locales::Scn::Latn';

done_testing();
