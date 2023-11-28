#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.3, Perl $], $^X" );
use ok Locale::CLDR::Locales::Zu;
use ok Locale::CLDR::Locales::Zu::Any::Za;
use ok Locale::CLDR::Locales::Zu::Any;

done_testing();
