#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.40.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Seh';
use ok 'Locale::CLDR::Locales::Seh::Any::Mz';
use ok 'Locale::CLDR::Locales::Seh::Any';

done_testing();
