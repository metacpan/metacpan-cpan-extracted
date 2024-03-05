#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Tg';
use ok 'Locale::CLDR::Locales::Tg::Cyrl::Tj';
use ok 'Locale::CLDR::Locales::Tg::Cyrl';

done_testing();
