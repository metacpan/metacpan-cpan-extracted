#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Be';
use ok 'Locale::CLDR::Locales::Be::Cyrl::By';
use ok 'Locale::CLDR::Locales::Be::Cyrl';
use ok 'Locale::CLDR::Locales::Be::Tarask';

done_testing();
