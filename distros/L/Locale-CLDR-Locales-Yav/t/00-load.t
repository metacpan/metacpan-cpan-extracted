#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Yav';
use ok 'Locale::CLDR::Locales::Yav::Latn::Cm';
use ok 'Locale::CLDR::Locales::Yav::Latn';

done_testing();
