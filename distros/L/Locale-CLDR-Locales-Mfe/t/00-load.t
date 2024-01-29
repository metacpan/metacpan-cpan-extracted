#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.40.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Mfe';
use ok 'Locale::CLDR::Locales::Mfe::Any::Mu';
use ok 'Locale::CLDR::Locales::Mfe::Any';

done_testing();
