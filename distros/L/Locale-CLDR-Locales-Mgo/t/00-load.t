#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Mgo';
use ok 'Locale::CLDR::Locales::Mgo::Latn::Cm';
use ok 'Locale::CLDR::Locales::Mgo::Latn';

done_testing();
