#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.40.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Sat';
use ok 'Locale::CLDR::Locales::Sat::Olck::In';
use ok 'Locale::CLDR::Locales::Sat::Olck';

done_testing();
