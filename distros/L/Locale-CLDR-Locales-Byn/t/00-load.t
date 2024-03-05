#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Byn';
use ok 'Locale::CLDR::Locales::Byn::Ethi::Er';
use ok 'Locale::CLDR::Locales::Byn::Ethi';

done_testing();
