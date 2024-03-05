#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Gl';
use ok 'Locale::CLDR::Locales::Gl::Latn::Es';
use ok 'Locale::CLDR::Locales::Gl::Latn';

done_testing();
