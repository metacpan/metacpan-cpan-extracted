#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.1, Perl $], $^X" );
use ok Locale::CLDR::Locales::Ccp, 'Can use locale file Locale::CLDR::Locales::Ccp';
use ok Locale::CLDR::Locales::Ccp::Any::In, 'Can use locale file Locale::CLDR::Locales::Ccp::Any::In';
use ok Locale::CLDR::Locales::Ccp::Any::Bd, 'Can use locale file Locale::CLDR::Locales::Ccp::Any::Bd';
use ok Locale::CLDR::Locales::Ccp::Any, 'Can use locale file Locale::CLDR::Locales::Ccp::Any';

done_testing();
