#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.40.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Nl';
use ok 'Locale::CLDR::Locales::Nl::Any::Aw';
use ok 'Locale::CLDR::Locales::Nl::Any::Be';
use ok 'Locale::CLDR::Locales::Nl::Any::Bq';
use ok 'Locale::CLDR::Locales::Nl::Any::Cw';
use ok 'Locale::CLDR::Locales::Nl::Any::Nl';
use ok 'Locale::CLDR::Locales::Nl::Any::Sr';
use ok 'Locale::CLDR::Locales::Nl::Any::Sx';
use ok 'Locale::CLDR::Locales::Nl::Any';

done_testing();
