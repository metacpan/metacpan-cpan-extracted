#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Lkt';
use ok 'Locale::CLDR::Locales::Lkt::Latn::Us';
use ok 'Locale::CLDR::Locales::Lkt::Latn';

done_testing();
