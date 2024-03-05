#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Kxv';
use ok 'Locale::CLDR::Locales::Kxv::Deva::In';
use ok 'Locale::CLDR::Locales::Kxv::Deva';
use ok 'Locale::CLDR::Locales::Kxv::Latn::In';
use ok 'Locale::CLDR::Locales::Kxv::Latn';
use ok 'Locale::CLDR::Locales::Kxv::Orya::In';
use ok 'Locale::CLDR::Locales::Kxv::Orya';
use ok 'Locale::CLDR::Locales::Kxv::Telu::In';
use ok 'Locale::CLDR::Locales::Kxv::Telu';

done_testing();
