#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Nyn';
use ok 'Locale::CLDR::Locales::Nyn::Latn::Ug';
use ok 'Locale::CLDR::Locales::Nyn::Latn';

done_testing();
