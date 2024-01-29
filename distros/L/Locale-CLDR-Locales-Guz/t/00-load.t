#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.40.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Guz';
use ok 'Locale::CLDR::Locales::Guz::Any::Ke';
use ok 'Locale::CLDR::Locales::Guz::Any';

done_testing();
