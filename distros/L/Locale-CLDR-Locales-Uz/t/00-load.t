#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.40.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Uz';
use ok 'Locale::CLDR::Locales::Uz::Arab::Af';
use ok 'Locale::CLDR::Locales::Uz::Arab';
use ok 'Locale::CLDR::Locales::Uz::Cyrl::Uz';
use ok 'Locale::CLDR::Locales::Uz::Cyrl';
use ok 'Locale::CLDR::Locales::Uz::Latn::Uz';
use ok 'Locale::CLDR::Locales::Uz::Latn';

done_testing();
