#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Devel::REPL::Plugin::ModuleAutoLoader' ) || print "Bail out!\n";
}

diag( "Testing Devel::REPL::Plugin::ModuleAutoLoader $Devel::REPL::Plugin::ModuleAutoLoader::VERSION, Perl $], $^X" );
