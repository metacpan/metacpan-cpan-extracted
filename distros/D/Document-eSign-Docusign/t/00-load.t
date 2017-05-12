#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Document::eSign::Docusign' ) || print "Bail out!\n";
}

diag( "Testing Document::eSign::Docusign $Document::eSign::Docusign::VERSION, Perl $], $^X" );
