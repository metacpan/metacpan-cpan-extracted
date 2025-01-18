#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Hi';
use ok 'Locale::CLDR::Locales::Hi::Deva::In';
use ok 'Locale::CLDR::Locales::Hi::Deva';
use ok 'Locale::CLDR::Locales::Hi::Latn::In';
use ok 'Locale::CLDR::Locales::Hi::Latn';

done_testing();
