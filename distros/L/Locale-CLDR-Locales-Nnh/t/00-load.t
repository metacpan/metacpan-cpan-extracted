#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Nnh';
use ok 'Locale::CLDR::Locales::Nnh::Latn::Cm';
use ok 'Locale::CLDR::Locales::Nnh::Latn';

done_testing();
