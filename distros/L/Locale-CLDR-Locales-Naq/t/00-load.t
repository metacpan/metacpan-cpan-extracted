#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Naq';
use ok 'Locale::CLDR::Locales::Naq::Latn::Na';
use ok 'Locale::CLDR::Locales::Naq::Latn';

done_testing();
