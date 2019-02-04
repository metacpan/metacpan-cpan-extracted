#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34, Perl $], $^X" );
use ok Locale::CLDR::Locales::Lt, 'Can use locale file Locale::CLDR::Locales::Lt';
use ok Locale::CLDR::Locales::Lt::Any::Lt, 'Can use locale file Locale::CLDR::Locales::Lt::Any::Lt';
use ok Locale::CLDR::Locales::Lt::Any, 'Can use locale file Locale::CLDR::Locales::Lt::Any';

done_testing();
