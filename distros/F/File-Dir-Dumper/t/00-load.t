#!perl -T

use Test::More tests => 2;

BEGIN {
    use_ok( 'File::Dir::Dumper' );
    use_ok( 'File::Dir::Dumper::App' );
}

diag( "Testing File::Dir::Dumper $File::Dir::Dumper::VERSION, Perl $], $^X" );
