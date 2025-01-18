#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Om';
use ok 'Locale::CLDR::Locales::Om::Latn::Et';
use ok 'Locale::CLDR::Locales::Om::Latn::Ke';
use ok 'Locale::CLDR::Locales::Om::Latn';

done_testing();
