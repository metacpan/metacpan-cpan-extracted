#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.32.0, Perl $], $^X" );
use ok Locale::CLDR::Locales::Kl, 'Can use locale file Locale::CLDR::Locales::Kl';
use ok Locale::CLDR::Locales::Kl::Any::Gl, 'Can use locale file Locale::CLDR::Locales::Kl::Any::Gl';
use ok Locale::CLDR::Locales::Kl::Any, 'Can use locale file Locale::CLDR::Locales::Kl::Any';

done_testing();
