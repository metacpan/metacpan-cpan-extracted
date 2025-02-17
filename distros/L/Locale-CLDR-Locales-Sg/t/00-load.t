#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Sg';
use ok 'Locale::CLDR::Locales::Sg::Latn::Cf';
use ok 'Locale::CLDR::Locales::Sg::Latn';

done_testing();
