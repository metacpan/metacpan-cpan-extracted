#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Pap';
use ok 'Locale::CLDR::Locales::Pap::Latn::Aw';
use ok 'Locale::CLDR::Locales::Pap::Latn::Cw';
use ok 'Locale::CLDR::Locales::Pap::Latn';

done_testing();
