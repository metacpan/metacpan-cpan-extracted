#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Nds';
use ok 'Locale::CLDR::Locales::Nds::Latn::De';
use ok 'Locale::CLDR::Locales::Nds::Latn::Nl';
use ok 'Locale::CLDR::Locales::Nds::Latn';

done_testing();
