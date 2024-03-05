#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Ta';
use ok 'Locale::CLDR::Locales::Ta::Taml::In';
use ok 'Locale::CLDR::Locales::Ta::Taml::Lk';
use ok 'Locale::CLDR::Locales::Ta::Taml::My';
use ok 'Locale::CLDR::Locales::Ta::Taml::Sg';
use ok 'Locale::CLDR::Locales::Ta::Taml';

done_testing();
