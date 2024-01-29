#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.40.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Tk';
use ok 'Locale::CLDR::Locales::Tk::Any::Tm';
use ok 'Locale::CLDR::Locales::Tk::Any';

done_testing();
