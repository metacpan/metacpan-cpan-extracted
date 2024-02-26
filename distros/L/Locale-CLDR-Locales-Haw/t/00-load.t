#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Haw';
use ok 'Locale::CLDR::Locales::Haw::Latn::Us';
use ok 'Locale::CLDR::Locales::Haw::Latn';

done_testing();
