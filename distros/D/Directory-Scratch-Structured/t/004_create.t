# test

use strict ;
use warnings ;

use Test::Exception ;
use Test::Warn;
use Test::NoWarnings ;

use Test::More 'no_plan';
use Test::Block qw($Plan);

use Directory::Scratch::Structured qw(create_structured_tree piggyback_directory_scratch) ; 

my %tree_structure =
	(
	file_0 => [] ,
	
	dir_1 =>
		{
		subdir_1 =>{},
		file_1 =>[],
		file_a => [],
		},
		
	dir_2 =>
		{
		subdir_2 =>
			{
			file_22 =>[],
			file_2a =>[],
			},
		file_2 =>[],
		file_a =>['12345'],
		file_b =>[],
		},
	) ;

my $base ;

{
local $Plan = {'non OO interface' => 5} ;

my $temporary_directory = create_structured_tree(%tree_structure) ;
$base = $temporary_directory->base() ;

ok(-e "$base/file_0", "file created") ;
ok(-e "$base/dir_1", "directory created") ;
ok(-e "$base/dir_1/subdir_1", "sub directory created") ;
ok(-e "$base/dir_1/file_1", "directory file created") ;

is(-s "$base/dir_2/file_a", 6, "sub directory file size ok") ;
}

{
local $Plan = {'OO interface' => 5} ;

my $scratch = Directory::Scratch->new;
$scratch->create_structured_tree(%tree_structure) ;

ok(-e "$base/file_0", "file created") ;
ok(-e "$base/dir_1", "directory created") ;
ok(-e "$base/dir_1/subdir_1", "sub directory created") ;
ok(-e "$base/dir_1/file_1", "directory file created") ;

is(-s "$base/dir_2/file_a", 6, "sub directory file size ok") ;
}


