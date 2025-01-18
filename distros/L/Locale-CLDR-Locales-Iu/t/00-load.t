#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Iu';
use ok 'Locale::CLDR::Locales::Iu::Cans::Ca';
use ok 'Locale::CLDR::Locales::Iu::Cans';
use ok 'Locale::CLDR::Locales::Iu::Latn::Ca';
use ok 'Locale::CLDR::Locales::Iu::Latn';

done_testing();
