#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.40.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Mgh';
use ok 'Locale::CLDR::Locales::Mgh::Any::Mz';
use ok 'Locale::CLDR::Locales::Mgh::Any';

done_testing();
