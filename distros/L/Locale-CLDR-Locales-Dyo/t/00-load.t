#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Dyo';
use ok 'Locale::CLDR::Locales::Dyo::Latn::Sn';
use ok 'Locale::CLDR::Locales::Dyo::Latn';

done_testing();
