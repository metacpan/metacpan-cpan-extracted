#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Gn';
use ok 'Locale::CLDR::Locales::Gn::Latn::Py';
use ok 'Locale::CLDR::Locales::Gn::Latn';

done_testing();
