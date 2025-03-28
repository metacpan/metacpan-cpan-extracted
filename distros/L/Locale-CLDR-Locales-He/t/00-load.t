#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::He';
use ok 'Locale::CLDR::Locales::He::Hebr::Il';
use ok 'Locale::CLDR::Locales::He::Hebr';

done_testing();
