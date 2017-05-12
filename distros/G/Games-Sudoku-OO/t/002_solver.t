# -*- perl -*-

# t/002_solver.t - use sudoku solver to solve test files 

use Test::More;
use File::Basename;
use strict;
use warnings;

my @test_files = <t/boards/*.txt t/boards/todo/*.txt>;

my %todo = (
    'grid2.txt' => {solved => 'inconsistent'},  
    'grid3.txt' => {solved => 'inconsistent'},
    'tough.txt' => {solved => 'inconsistent'},
    );

plan tests => (@test_files)* 3;

use Games::Sudoku::OO::Board;

foreach (@test_files){
    test($_);
}	
   

sub test {
    my $board_file = shift;
    my $board = new Games::Sudoku::OO::Board;
    
    ok($board->importGrid($board_file), "import $board_file");
  TODO:{
    local $TODO = 
	( $todo{basename($board_file)}{solveAll} ) 
	|| undef;
    
    
    ok($board->solveAll($board_file), "solveAll $board_file");
    TODO:{
	local $TODO = 
	  ( $todo{basename($board_file)}{solved} ) || undef;
      SKIP:{
	skip "need to generate ${board_file}.solution", 1 unless -f "${board_file}.solution";
	
	open(my $fh, "${board_file}.solution");
	local $/ = undef;
	my $solved = <$fh>;
	close $fh;
	
	is($board->toStr(), $solved, "got ${board_file}.solved solution"); 
      }
    }
  }    
}



