#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Guz';
use ok 'Locale::CLDR::Locales::Guz::Latn::Ke';
use ok 'Locale::CLDR::Locales::Guz::Latn';

done_testing();
