#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'File::Find::Rule::LibMagic' ) || print "Bail out!
";
}

diag( "Testing File::Find::Rule::LibMagic $File::Find::Rule::LibMagic::VERSION, Perl $], $^X" );
diag( "Using File::LibMagic: $File::LibMagic::VERSION, Text::Glob: $Text::Glob::VERSION, File::Find::Rule: $File::Find::Rule::VERSION" );
