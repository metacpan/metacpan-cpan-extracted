#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Nv';
use ok 'Locale::CLDR::Locales::Nv::Latn::Us';
use ok 'Locale::CLDR::Locales::Nv::Latn';

done_testing();
