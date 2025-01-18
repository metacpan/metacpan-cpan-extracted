#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Rif';
use ok 'Locale::CLDR::Locales::Rif::Latn::Ma';
use ok 'Locale::CLDR::Locales::Rif::Latn';

done_testing();
