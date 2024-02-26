#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Ast';
use ok 'Locale::CLDR::Locales::Ast::Latn::Es';
use ok 'Locale::CLDR::Locales::Ast::Latn';

done_testing();
