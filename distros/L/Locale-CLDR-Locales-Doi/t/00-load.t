#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.40.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Doi';
use ok 'Locale::CLDR::Locales::Doi::Any::In';
use ok 'Locale::CLDR::Locales::Doi::Any';

done_testing();
