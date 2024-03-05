#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Hr';
use ok 'Locale::CLDR::Locales::Hr::Latn::Ba';
use ok 'Locale::CLDR::Locales::Hr::Latn::Hr';
use ok 'Locale::CLDR::Locales::Hr::Latn';

done_testing();
