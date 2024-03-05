#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Ceb';
use ok 'Locale::CLDR::Locales::Ceb::Latn::Ph';
use ok 'Locale::CLDR::Locales::Ceb::Latn';

done_testing();
