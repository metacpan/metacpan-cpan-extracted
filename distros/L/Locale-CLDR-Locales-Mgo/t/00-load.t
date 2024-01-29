#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.40.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Mgo';
use ok 'Locale::CLDR::Locales::Mgo::Any::Cm';
use ok 'Locale::CLDR::Locales::Mgo::Any';

done_testing();
