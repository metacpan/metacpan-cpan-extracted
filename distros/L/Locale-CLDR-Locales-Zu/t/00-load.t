#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Zu';
use ok 'Locale::CLDR::Locales::Zu::Latn::Za';
use ok 'Locale::CLDR::Locales::Zu::Latn';

done_testing();
