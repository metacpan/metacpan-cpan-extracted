#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Xog';
use ok 'Locale::CLDR::Locales::Xog::Latn::Ug';
use ok 'Locale::CLDR::Locales::Xog::Latn';

done_testing();
