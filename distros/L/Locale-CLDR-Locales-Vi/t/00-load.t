#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Vi';
use ok 'Locale::CLDR::Locales::Vi::Latn::Vn';
use ok 'Locale::CLDR::Locales::Vi::Latn';

done_testing();
