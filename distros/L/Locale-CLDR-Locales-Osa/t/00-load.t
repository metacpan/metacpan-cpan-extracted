#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Osa';
use ok 'Locale::CLDR::Locales::Osa::Osge::Us';
use ok 'Locale::CLDR::Locales::Osa::Osge';

done_testing();
