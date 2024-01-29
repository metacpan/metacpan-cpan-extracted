#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.40.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::It';
use ok 'Locale::CLDR::Locales::It::Any::Ch';
use ok 'Locale::CLDR::Locales::It::Any::It';
use ok 'Locale::CLDR::Locales::It::Any::Sm';
use ok 'Locale::CLDR::Locales::It::Any::Va';
use ok 'Locale::CLDR::Locales::It::Any';

done_testing();
