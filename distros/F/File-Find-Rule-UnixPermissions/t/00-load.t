#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'File::Find::Rule::UnixPermissions' ) || print "Bail out!\n";
}

diag( "Testing File::Find::Rule::UnixPermissions $File::Find::Rule::UnixPermissions::VERSION, Perl $], $^X" );
