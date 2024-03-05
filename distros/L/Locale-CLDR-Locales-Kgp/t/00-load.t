#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Kgp';
use ok 'Locale::CLDR::Locales::Kgp::Latn::Br';
use ok 'Locale::CLDR::Locales::Kgp::Latn';

done_testing();
