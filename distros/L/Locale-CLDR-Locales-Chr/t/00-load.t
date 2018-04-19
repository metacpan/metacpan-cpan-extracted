#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.32.0, Perl $], $^X" );
use ok Locale::CLDR::Locales::Chr, 'Can use locale file Locale::CLDR::Locales::Chr';
use ok Locale::CLDR::Locales::Chr::Any::Us, 'Can use locale file Locale::CLDR::Locales::Chr::Any::Us';
use ok Locale::CLDR::Locales::Chr::Any, 'Can use locale file Locale::CLDR::Locales::Chr::Any';

done_testing();
