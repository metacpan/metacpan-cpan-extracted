#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Zgh';
use ok 'Locale::CLDR::Locales::Zgh::Tfng::Ma';
use ok 'Locale::CLDR::Locales::Zgh::Tfng';

done_testing();
