#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.40.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Vi';
use ok 'Locale::CLDR::Locales::Vi::Any::Vn';
use ok 'Locale::CLDR::Locales::Vi::Any';

done_testing();
