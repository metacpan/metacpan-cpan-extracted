#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Ne';
use ok 'Locale::CLDR::Locales::Ne::Deva::In';
use ok 'Locale::CLDR::Locales::Ne::Deva::Np';
use ok 'Locale::CLDR::Locales::Ne::Deva';

done_testing();
