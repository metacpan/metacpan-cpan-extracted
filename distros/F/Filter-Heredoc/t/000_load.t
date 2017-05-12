#!perl

use Test::More tests => 3;

BEGIN {
    use_ok( 'Filter::Heredoc' ) || print "Bail out!\n";
    use_ok( 'Filter::Heredoc::Rule' ) || print "Bail out!\n";
    use_ok( 'Filter::Heredoc::App' ) || print "Bail out!\n";
}

diag( "Testing Filter::Heredoc $Filter::Heredoc::VERSION, Perl $], $^X" );
