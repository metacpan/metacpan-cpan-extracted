#!perl -T

use strict;
use warnings;

use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 1;


BEGIN
{
	use_ok( 'Git::Repository::Plugin::Blame' );
}

diag( "Testing Git::Repository::Plugin::Blame $Git::Repository::Plugin::Blame::VERSION, Perl $], $^X" );
