#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Kkj';
use ok 'Locale::CLDR::Locales::Kkj::Latn::Cm';
use ok 'Locale::CLDR::Locales::Kkj::Latn';

done_testing();
