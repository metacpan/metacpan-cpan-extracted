#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Kpe';
use ok 'Locale::CLDR::Locales::Kpe::Latn::Gn';
use ok 'Locale::CLDR::Locales::Kpe::Latn::Lr';
use ok 'Locale::CLDR::Locales::Kpe::Latn';

done_testing();
