#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.33.1, Perl $], $^X" );
use ok Locale::CLDR::Locales::Am, 'Can use locale file Locale::CLDR::Locales::Am';
use ok Locale::CLDR::Locales::Am::Any::Et, 'Can use locale file Locale::CLDR::Locales::Am::Any::Et';
use ok Locale::CLDR::Locales::Am::Any, 'Can use locale file Locale::CLDR::Locales::Am::Any';

done_testing();
