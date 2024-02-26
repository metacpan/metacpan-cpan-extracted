#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Am';
use ok 'Locale::CLDR::Locales::Am::Ethi::Et';
use ok 'Locale::CLDR::Locales::Am::Ethi';

done_testing();
