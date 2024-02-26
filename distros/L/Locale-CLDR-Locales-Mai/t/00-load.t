#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Mai';
use ok 'Locale::CLDR::Locales::Mai::Deva::In';
use ok 'Locale::CLDR::Locales::Mai::Deva';

done_testing();
