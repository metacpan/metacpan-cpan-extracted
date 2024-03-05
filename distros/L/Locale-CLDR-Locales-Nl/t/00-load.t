#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Nl';
use ok 'Locale::CLDR::Locales::Nl::Latn::Aw';
use ok 'Locale::CLDR::Locales::Nl::Latn::Be';
use ok 'Locale::CLDR::Locales::Nl::Latn::Bq';
use ok 'Locale::CLDR::Locales::Nl::Latn::Cw';
use ok 'Locale::CLDR::Locales::Nl::Latn::Nl';
use ok 'Locale::CLDR::Locales::Nl::Latn::Sr';
use ok 'Locale::CLDR::Locales::Nl::Latn::Sx';
use ok 'Locale::CLDR::Locales::Nl::Latn';

done_testing();
