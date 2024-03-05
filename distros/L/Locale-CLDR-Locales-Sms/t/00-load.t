#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Sms';
use ok 'Locale::CLDR::Locales::Sms::Latn::Fi';
use ok 'Locale::CLDR::Locales::Sms::Latn';

done_testing();
