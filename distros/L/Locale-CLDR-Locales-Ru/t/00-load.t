#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Ru';
use ok 'Locale::CLDR::Locales::Ru::Cyrl::By';
use ok 'Locale::CLDR::Locales::Ru::Cyrl::Kg';
use ok 'Locale::CLDR::Locales::Ru::Cyrl::Kz';
use ok 'Locale::CLDR::Locales::Ru::Cyrl::Md';
use ok 'Locale::CLDR::Locales::Ru::Cyrl::Ru';
use ok 'Locale::CLDR::Locales::Ru::Cyrl::Ua';
use ok 'Locale::CLDR::Locales::Ru::Cyrl';

done_testing();
