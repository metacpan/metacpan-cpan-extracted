#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Bas';
use ok 'Locale::CLDR::Locales::Bas::Latn::Cm';
use ok 'Locale::CLDR::Locales::Bas::Latn';

done_testing();
