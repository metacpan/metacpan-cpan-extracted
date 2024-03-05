#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Kaj';
use ok 'Locale::CLDR::Locales::Kaj::Latn::Ng';
use ok 'Locale::CLDR::Locales::Kaj::Latn';

done_testing();
