#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Ann';
use ok 'Locale::CLDR::Locales::Ann::Latn::Ng';
use ok 'Locale::CLDR::Locales::Ann::Latn';

done_testing();
