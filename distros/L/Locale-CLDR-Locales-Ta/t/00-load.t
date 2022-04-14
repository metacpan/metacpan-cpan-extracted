#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.1, Perl $], $^X" );
use ok Locale::CLDR::Locales::Ta, 'Can use locale file Locale::CLDR::Locales::Ta';
use ok Locale::CLDR::Locales::Ta::Any::My, 'Can use locale file Locale::CLDR::Locales::Ta::Any::My';
use ok Locale::CLDR::Locales::Ta::Any::Sg, 'Can use locale file Locale::CLDR::Locales::Ta::Any::Sg';
use ok Locale::CLDR::Locales::Ta::Any::Lk, 'Can use locale file Locale::CLDR::Locales::Ta::Any::Lk';
use ok Locale::CLDR::Locales::Ta::Any::In, 'Can use locale file Locale::CLDR::Locales::Ta::Any::In';
use ok Locale::CLDR::Locales::Ta::Any, 'Can use locale file Locale::CLDR::Locales::Ta::Any';

done_testing();
