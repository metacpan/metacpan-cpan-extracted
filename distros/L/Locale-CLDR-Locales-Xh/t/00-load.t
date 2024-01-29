#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.40.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Xh';
use ok 'Locale::CLDR::Locales::Xh::Any::Za';
use ok 'Locale::CLDR::Locales::Xh::Any';

done_testing();
