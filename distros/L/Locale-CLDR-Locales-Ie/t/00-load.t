#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Ie';
use ok 'Locale::CLDR::Locales::Ie::Latn::Ee';
use ok 'Locale::CLDR::Locales::Ie::Latn';

done_testing();
