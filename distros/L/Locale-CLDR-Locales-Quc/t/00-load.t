#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Quc';
use ok 'Locale::CLDR::Locales::Quc::Latn::Gt';
use ok 'Locale::CLDR::Locales::Quc::Latn';

done_testing();
