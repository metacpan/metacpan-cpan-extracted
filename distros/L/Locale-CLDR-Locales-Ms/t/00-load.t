#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Ms';
use ok 'Locale::CLDR::Locales::Ms::Arab::Bn';
use ok 'Locale::CLDR::Locales::Ms::Arab::My';
use ok 'Locale::CLDR::Locales::Ms::Arab';
use ok 'Locale::CLDR::Locales::Ms::Latn::Bn';
use ok 'Locale::CLDR::Locales::Ms::Latn::Id';
use ok 'Locale::CLDR::Locales::Ms::Latn::My';
use ok 'Locale::CLDR::Locales::Ms::Latn::Sg';
use ok 'Locale::CLDR::Locales::Ms::Latn';

done_testing();
