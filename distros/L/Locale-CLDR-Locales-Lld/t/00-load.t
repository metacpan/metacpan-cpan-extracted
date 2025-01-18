#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Lld';
use ok 'Locale::CLDR::Locales::Lld::Latn::It';
use ok 'Locale::CLDR::Locales::Lld::Latn';

done_testing();
