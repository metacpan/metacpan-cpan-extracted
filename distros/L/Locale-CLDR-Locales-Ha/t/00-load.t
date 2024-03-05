#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Ha';
use ok 'Locale::CLDR::Locales::Ha::Arab::Ng';
use ok 'Locale::CLDR::Locales::Ha::Arab::Sd';
use ok 'Locale::CLDR::Locales::Ha::Arab';
use ok 'Locale::CLDR::Locales::Ha::Latn::Gh';
use ok 'Locale::CLDR::Locales::Ha::Latn::Ne';
use ok 'Locale::CLDR::Locales::Ha::Latn::Ng';
use ok 'Locale::CLDR::Locales::Ha::Latn';

done_testing();
