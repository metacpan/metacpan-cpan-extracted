#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Ss';
use ok 'Locale::CLDR::Locales::Ss::Latn::Sz';
use ok 'Locale::CLDR::Locales::Ss::Latn::Za';
use ok 'Locale::CLDR::Locales::Ss::Latn';

done_testing();
