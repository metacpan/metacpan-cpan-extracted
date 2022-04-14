#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.1, Perl $], $^X" );
use ok Locale::CLDR::Locales::Zh, 'Can use locale file Locale::CLDR::Locales::Zh';
use ok Locale::CLDR::Locales::Zh::Hant, 'Can use locale file Locale::CLDR::Locales::Zh::Hant';
use ok Locale::CLDR::Locales::Zh::Hans::Sg, 'Can use locale file Locale::CLDR::Locales::Zh::Hans::Sg';
use ok Locale::CLDR::Locales::Zh::Hans::Hk, 'Can use locale file Locale::CLDR::Locales::Zh::Hans::Hk';
use ok Locale::CLDR::Locales::Zh::Hans::Mo, 'Can use locale file Locale::CLDR::Locales::Zh::Hans::Mo';
use ok Locale::CLDR::Locales::Zh::Hans::Cn, 'Can use locale file Locale::CLDR::Locales::Zh::Hans::Cn';
use ok Locale::CLDR::Locales::Zh::Hant::Hk, 'Can use locale file Locale::CLDR::Locales::Zh::Hant::Hk';
use ok Locale::CLDR::Locales::Zh::Hant::Mo, 'Can use locale file Locale::CLDR::Locales::Zh::Hant::Mo';
use ok Locale::CLDR::Locales::Zh::Hant::Tw, 'Can use locale file Locale::CLDR::Locales::Zh::Hant::Tw';
use ok Locale::CLDR::Locales::Zh::Hans, 'Can use locale file Locale::CLDR::Locales::Zh::Hans';

done_testing();
