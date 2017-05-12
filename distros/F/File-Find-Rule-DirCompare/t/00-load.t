#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'File::Find::Rule::DirCompare' ) || print "Bail out!
";
}

diag( "Testing File::Find::Rule::DirCompare $File::Find::Rule::DirCompare::VERSION, Perl $], $^X" );
