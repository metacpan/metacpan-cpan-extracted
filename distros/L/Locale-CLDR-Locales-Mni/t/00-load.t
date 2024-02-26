#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Mni';
use ok 'Locale::CLDR::Locales::Mni::Beng::In';
use ok 'Locale::CLDR::Locales::Mni::Beng';
use ok 'Locale::CLDR::Locales::Mni::Mtei::In';
use ok 'Locale::CLDR::Locales::Mni::Mtei';

done_testing();
