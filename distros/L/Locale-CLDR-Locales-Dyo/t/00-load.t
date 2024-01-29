#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.40.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Dyo';
use ok 'Locale::CLDR::Locales::Dyo::Any::Sn';
use ok 'Locale::CLDR::Locales::Dyo::Any';

done_testing();
