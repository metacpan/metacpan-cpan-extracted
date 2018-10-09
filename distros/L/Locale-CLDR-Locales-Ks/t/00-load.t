#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.33.1, Perl $], $^X" );
use ok Locale::CLDR::Locales::Ks, 'Can use locale file Locale::CLDR::Locales::Ks';
use ok Locale::CLDR::Locales::Ks::Any::In, 'Can use locale file Locale::CLDR::Locales::Ks::Any::In';
use ok Locale::CLDR::Locales::Ks::Any, 'Can use locale file Locale::CLDR::Locales::Ks::Any';

done_testing();
