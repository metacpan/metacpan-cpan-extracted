#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.40.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Kgp';
use ok 'Locale::CLDR::Locales::Kgp::Any::Br';
use ok 'Locale::CLDR::Locales::Kgp::Any';

done_testing();
