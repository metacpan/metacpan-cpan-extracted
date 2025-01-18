#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::El';
use ok 'Locale::CLDR::Locales::El::Grek::Cy';
use ok 'Locale::CLDR::Locales::El::Grek::Gr';
use ok 'Locale::CLDR::Locales::El::Grek';
use ok 'Locale::CLDR::Locales::El::Polyton';

done_testing();
