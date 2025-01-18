#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::It';
use ok 'Locale::CLDR::Locales::It::Latn::Ch';
use ok 'Locale::CLDR::Locales::It::Latn::It';
use ok 'Locale::CLDR::Locales::It::Latn::Sm';
use ok 'Locale::CLDR::Locales::It::Latn::Va';
use ok 'Locale::CLDR::Locales::It::Latn';

done_testing();
