#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.40.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Et';
use ok 'Locale::CLDR::Locales::Et::Any::Ee';
use ok 'Locale::CLDR::Locales::Et::Any';

done_testing();
