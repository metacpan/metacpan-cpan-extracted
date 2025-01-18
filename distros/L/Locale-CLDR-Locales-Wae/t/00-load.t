#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Wae';
use ok 'Locale::CLDR::Locales::Wae::Latn::Ch';
use ok 'Locale::CLDR::Locales::Wae::Latn';

done_testing();
