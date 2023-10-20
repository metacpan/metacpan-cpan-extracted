#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.2, Perl $], $^X" );
use ok Locale::CLDR::Locales::Ast;
use ok Locale::CLDR::Locales::Ast::Any::Es;
use ok Locale::CLDR::Locales::Ast::Any;

done_testing();
