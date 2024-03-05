#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Bs';
use ok 'Locale::CLDR::Locales::Bs::Cyrl::Ba';
use ok 'Locale::CLDR::Locales::Bs::Cyrl';
use ok 'Locale::CLDR::Locales::Bs::Latn::Ba';
use ok 'Locale::CLDR::Locales::Bs::Latn';

done_testing();
