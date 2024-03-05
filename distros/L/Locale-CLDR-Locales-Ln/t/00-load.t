#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Ln';
use ok 'Locale::CLDR::Locales::Ln::Latn::Ao';
use ok 'Locale::CLDR::Locales::Ln::Latn::Cd';
use ok 'Locale::CLDR::Locales::Ln::Latn::Cf';
use ok 'Locale::CLDR::Locales::Ln::Latn::Cg';
use ok 'Locale::CLDR::Locales::Ln::Latn';

done_testing();
