#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Cch';
use ok 'Locale::CLDR::Locales::Cch::Latn::Ng';
use ok 'Locale::CLDR::Locales::Cch::Latn';

done_testing();
