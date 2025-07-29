#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Git::RemoteURL::Parse' ) || print "Bail out!\n";
}

diag( "Testing Git::RemoteURL::Parse $Git::RemoteURL::Parse::VERSION, Perl $], $^X" );
