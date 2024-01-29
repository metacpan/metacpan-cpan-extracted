#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.40.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Mai';
use ok 'Locale::CLDR::Locales::Mai::Any::In';
use ok 'Locale::CLDR::Locales::Mai::Any';

done_testing();
