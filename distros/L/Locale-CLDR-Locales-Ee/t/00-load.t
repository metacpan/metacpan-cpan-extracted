#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Ee';
use ok 'Locale::CLDR::Locales::Ee::Latn::Gh';
use ok 'Locale::CLDR::Locales::Ee::Latn::Tg';
use ok 'Locale::CLDR::Locales::Ee::Latn';

done_testing();
