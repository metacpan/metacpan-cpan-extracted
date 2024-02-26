#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Zh';
use ok 'Locale::CLDR::Locales::Zh::Hans::Cn';
use ok 'Locale::CLDR::Locales::Zh::Hans::Hk';
use ok 'Locale::CLDR::Locales::Zh::Hans::Mo';
use ok 'Locale::CLDR::Locales::Zh::Hans::Sg';
use ok 'Locale::CLDR::Locales::Zh::Hans';
use ok 'Locale::CLDR::Locales::Zh::Hant::Hk';
use ok 'Locale::CLDR::Locales::Zh::Hant::Mo';
use ok 'Locale::CLDR::Locales::Zh::Hant::Tw';
use ok 'Locale::CLDR::Locales::Zh::Hant';

done_testing();
