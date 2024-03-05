#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Lo';
use ok 'Locale::CLDR::Locales::Lo::Laoo::La';
use ok 'Locale::CLDR::Locales::Lo::Laoo';

done_testing();
