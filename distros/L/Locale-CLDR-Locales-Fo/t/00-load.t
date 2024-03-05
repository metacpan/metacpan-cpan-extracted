#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Fo';
use ok 'Locale::CLDR::Locales::Fo::Latn::Dk';
use ok 'Locale::CLDR::Locales::Fo::Latn::Fo';
use ok 'Locale::CLDR::Locales::Fo::Latn';

done_testing();
