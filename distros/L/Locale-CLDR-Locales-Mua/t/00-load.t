#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Mua';
use ok 'Locale::CLDR::Locales::Mua::Latn::Cm';
use ok 'Locale::CLDR::Locales::Mua::Latn';

done_testing();
