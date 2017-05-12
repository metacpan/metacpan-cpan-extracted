# test find method

use strict ;
use warnings ;

use Test::Exception ;
use Test::Warn;
use Test::NoWarnings ;

use Test::More 'no_plan';
use Test::Block qw($Plan);

use File::Find::Repository ; 
use Directory::Scratch ;

{
local $Plan = {'find' => 8} ;

my $temporary_directory  = 
	create_directories
		({
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
			file_a =>[],
			file_b =>[],
			},
			
		dir_3 =>
			{
			subdir_3 =>{},
			file_3 =>[],
			file_a =>[],
			file_b =>[],
			file_c =>[],
			},
			
		file_0 => [],
		}) ;

my $base = $temporary_directory->base() ;


# test default WHICH
# test WHICH
# find in multiple repositories

my @found_files ;
my $locator = new File::Find::Repository
		(
		NAME => 'Find1',
		
		REPOSITORIES =>
			[
			"$base",
			"$base/dir_1",
			"$base/dir_2",
			"$base/dir_3",
			],
			
		WHICH => sub 
				{
				my ($object, $located_files) = @_ ;
				
				@found_files = keys %$located_files ;
				
				return File::Find::Repository::FIRST_FOUND($object, $located_files) ;
				} ,
				
		#~ VERBOSE => 1,
		#~ INTERACTION => {INFO => \&diag} ,
		) ;

my $located_file = $locator->Find('file_a') ;
is(scalar(@found_files), 3, "found all files in repositories") ;
is($located_file, "$base/dir_1/file_a", "returned first ") ;

@found_files = () ;
$located_file = $locator->Find('file_b') ;
is(scalar(@found_files), 2, "found all files in repositories") ;
is($located_file, "$base/dir_2/file_b", "returned first ") ;

@found_files = () ;
$located_file = $locator->Find('file_c') ;
is(scalar(@found_files), 1, "found all files in repositories") ;
is($located_file, "$base/dir_3/file_c", "returned first ") ;

# don't find
@found_files = () ;
$located_file = $locator->Find('file_x') ;
is(scalar(@found_files), 0, "found no files in repositories") ;
is($located_file, undef, "returned undef") ;
}

{
local $Plan = {'find' => 4} ;

my $temporary_directory  = 
	create_directories
		({
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
			file_a =>['12345'], # \n is added to each element, size id 6 here
			file_b =>[],
			},
			
		dir_3 =>
			{
			subdir_3 =>{},
			file_3 =>[],
			file_a =>[],
			file_b =>[],
			file_c =>[],
			},
			
		file_0 => [] ,
		}) ;

my $base = $temporary_directory->base() ;
#~ diag `tree -s $base` ;

# test WHICH
# test FULL_INFO
# use sub repositories

my @found_files ;
my $locator = new File::Find::Repository
		(
		NAME => 'Find2',
		
		REPOSITORIES =>
			[
			"$base",
			"$base/dir_1",
			"$base/dir_2",
			"$base/dir_3",
			sub {return 'somewhere_under_the_rainbow/file_a';},
			],
			
		WHICH => sub 
				{
				my ($object, $located_files) = @_ ;
				
				@found_files = keys %$located_files ;
				
				return($located_files->{"$base/dir_2/file_a"}) ;
				},
				
		FULL_INFO => \&File::Find::Repository::TIME_AND_SIZE,
		) ;

my $located_files = $locator->Find(FILES=>['file_a']) ;

#~ use Data::TreeDumper ;
#~ diag DumpTree $located_files ;

is(scalar(@found_files), 4, "sub repository called") ;
is($found_files[3], 'somewhere_under_the_rainbow/file_a', "virtual file from sub repository") ;
is($located_files->{'file_a'}{FOUND_AT}, "$base/dir_2/file_a", "WHICH ok") ;
is($located_files->{'file_a'}{SIZE}, 6, "FULL_INFO ok") ;
}

#-----------------------------------------------------------------------------------

sub create_directories
{
my ($directory, $temporary_directory, $path) = @_ ;

$temporary_directory = new Directory::Scratch() unless defined $temporary_directory ;
$path = '.' unless defined $path ;

while( my ($entry_name, $contents) = each %$directory)
	{
	for($contents)
		{
		'ARRAY' eq ref $_ and do
			{
			my $file = $temporary_directory->touch("$path/$entry_name", @$contents) ;
			last ;
			} ;
			
		'HASH' eq ref $_ and do
			{
			my $dir  = $temporary_directory->mkdir("$path/$entry_name");
			create_directories($contents, $temporary_directory, "$path/$entry_name") ;
			last ;
			} ;
			
		die "invalid element '$path/$entry_name' in directory structure\n" ;
		}
	}

return($temporary_directory ) ;
}

=comment

{
local $Plan = {'' => } ;

is(result, expected, "message") ;

dies_ok
	{
	
	} "" ;

lives_ok
	{
	
	} "" ;

like(result, qr//, '') ;

warning_like
	{
	} qr//i, "";

is_deeply
	(
	generated,
	[],
	'expected values'
	) ;
}

=cut
