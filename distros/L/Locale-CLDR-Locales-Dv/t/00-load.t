#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Dv';
use ok 'Locale::CLDR::Locales::Dv::Thaa::Mv';
use ok 'Locale::CLDR::Locales::Dv::Thaa';

done_testing();
