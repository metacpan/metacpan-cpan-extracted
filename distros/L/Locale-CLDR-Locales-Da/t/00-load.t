#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.40.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Da';
use ok 'Locale::CLDR::Locales::Da::Any::Dk';
use ok 'Locale::CLDR::Locales::Da::Any::Gl';
use ok 'Locale::CLDR::Locales::Da::Any';

done_testing();
