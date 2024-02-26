#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Mn';
use ok 'Locale::CLDR::Locales::Mn::Cyrl::Mn';
use ok 'Locale::CLDR::Locales::Mn::Cyrl';
use ok 'Locale::CLDR::Locales::Mn::Mong::Cn';
use ok 'Locale::CLDR::Locales::Mn::Mong::Mn';
use ok 'Locale::CLDR::Locales::Mn::Mong';

done_testing();
