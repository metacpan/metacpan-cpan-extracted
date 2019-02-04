#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34, Perl $], $^X" );
use ok Locale::CLDR::Locales::Nds, 'Can use locale file Locale::CLDR::Locales::Nds';
use ok Locale::CLDR::Locales::Nds::Any::De, 'Can use locale file Locale::CLDR::Locales::Nds::Any::De';
use ok Locale::CLDR::Locales::Nds::Any::Nl, 'Can use locale file Locale::CLDR::Locales::Nds::Any::Nl';
use ok Locale::CLDR::Locales::Nds::Any, 'Can use locale file Locale::CLDR::Locales::Nds::Any';

done_testing();
