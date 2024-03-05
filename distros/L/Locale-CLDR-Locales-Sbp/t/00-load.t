#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Sbp';
use ok 'Locale::CLDR::Locales::Sbp::Latn::Tz';
use ok 'Locale::CLDR::Locales::Sbp::Latn';

done_testing();
