#!perl -T

use Test::More tests => 3;

BEGIN {
	use_ok( 'Hardware::Vhdl::Automake::Project' );
	use_ok( 'Hardware::Vhdl::Automake::PreProcessor::Cish' );
	use_ok( 'Hardware::Vhdl::Automake::Compiler::ModelSim' );
}

#~ diag( "Testing Hardware::Vhdl::Automake::Project $Hardware::Vhdl::Automake::Project::VERSION, Perl $], $^X" );
diag( "Testing Hardware::Vhdl::Automake::Project, Perl $], $^X" );
