#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Kaa';
use ok 'Locale::CLDR::Locales::Kaa::Cyrl::Uz';
use ok 'Locale::CLDR::Locales::Kaa::Cyrl';
use ok 'Locale::CLDR::Locales::Kaa::Latn::Uz';
use ok 'Locale::CLDR::Locales::Kaa::Latn';

done_testing();
