#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Sa';
use ok 'Locale::CLDR::Locales::Sa::Deva::In';
use ok 'Locale::CLDR::Locales::Sa::Deva';

done_testing();
