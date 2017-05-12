#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.29.0, Perl 5.018002, D:\strawberry\perl\bin\perl.exe" );
use ok Locale::CLDR::Locales::Ast, 'Can use locale file Locale::CLDR::Locales::Ast';
use ok Locale::CLDR::Locales::Ast::Any::Es, 'Can use locale file Locale::CLDR::Locales::Ast::Any::Es';
use ok Locale::CLDR::Locales::Ast::Any, 'Can use locale file Locale::CLDR::Locales::Ast::Any';

done_testing();
