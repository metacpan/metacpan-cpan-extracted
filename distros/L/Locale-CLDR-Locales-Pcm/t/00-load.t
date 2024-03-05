#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Pcm';
use ok 'Locale::CLDR::Locales::Pcm::Latn::Ng';
use ok 'Locale::CLDR::Locales::Pcm::Latn';

done_testing();
