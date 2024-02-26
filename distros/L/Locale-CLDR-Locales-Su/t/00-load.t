#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Su';
use ok 'Locale::CLDR::Locales::Su::Latn::Id';
use ok 'Locale::CLDR::Locales::Su::Latn';

done_testing();
