#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.40.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Am';
use ok 'Locale::CLDR::Locales::Am::Any::Et';
use ok 'Locale::CLDR::Locales::Am::Any';

done_testing();
