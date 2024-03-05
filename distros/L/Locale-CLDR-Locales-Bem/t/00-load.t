#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Bem';
use ok 'Locale::CLDR::Locales::Bem::Latn::Zm';
use ok 'Locale::CLDR::Locales::Bem::Latn';

done_testing();
