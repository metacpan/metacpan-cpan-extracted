#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Tig';
use ok 'Locale::CLDR::Locales::Tig::Ethi::Er';
use ok 'Locale::CLDR::Locales::Tig::Ethi';

done_testing();
