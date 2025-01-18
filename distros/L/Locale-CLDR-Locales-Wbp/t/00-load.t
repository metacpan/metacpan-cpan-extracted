#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Wbp';
use ok 'Locale::CLDR::Locales::Wbp::Latn::Au';
use ok 'Locale::CLDR::Locales::Wbp::Latn';

done_testing();
