#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Sat';
use ok 'Locale::CLDR::Locales::Sat::Deva::In';
use ok 'Locale::CLDR::Locales::Sat::Deva';
use ok 'Locale::CLDR::Locales::Sat::Olck::In';
use ok 'Locale::CLDR::Locales::Sat::Olck';

done_testing();
