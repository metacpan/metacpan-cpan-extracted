#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Sn';
use ok 'Locale::CLDR::Locales::Sn::Latn::Zw';
use ok 'Locale::CLDR::Locales::Sn::Latn';

done_testing();
