#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Bgc';
use ok 'Locale::CLDR::Locales::Bgc::Deva::In';
use ok 'Locale::CLDR::Locales::Bgc::Deva';

done_testing();
