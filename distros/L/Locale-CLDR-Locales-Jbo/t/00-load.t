#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Jbo';
use ok 'Locale::CLDR::Locales::Jbo::Latn::001';
use ok 'Locale::CLDR::Locales::Jbo::Latn';

done_testing();
