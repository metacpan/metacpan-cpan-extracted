# interaction sub test

use strict ;
use warnings ;

use Test::Exception ;
use Test::Warn;
use Test::NoWarnings ;

use Test::More 'no_plan';
use Test::Block qw($Plan);

use File::Find::Repository ; 
use Directory::Scratch;

my $test_directory_structure =
	{
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
	} ;

{
local $Plan = {'INTERACTION' => 12} ;

my (@info_messages, @warn_messages, @die_messages);

my $info = sub {push @info_messages, [@_]} ;
my $warn = sub {push @warn_messages, [@_]} ;
my $die = sub {push @die_messages, [@_]; die @_} ;
	
my $temporary_directory  = create_directories($test_directory_structure) ;

my $base = $temporary_directory->base() ;

my $locator = new File::Find::Repository
				(
				NAME            => 'verbose test',
				VERBOSE         => 1,
				INTERACTION     => 
					{
					INFO  => $info,
					WARN  => $warn,
					DIE   => $die,
					},
					
				REPOSITORIES =>
					[
					"$base",
					"$base/dir_1",
					"$base/dir_2",
					"$base/dir_3",
					],
				) ;

use Data::TreeDumper ;
my $located_file = $locator->Find('file_a') ;
is(@info_messages, 5, "info messages") or diag DumpTree \@info_messages;
like($info_messages[0][0], qr/Searching for 'file_a'/, "search header") ;
like($info_messages[1][0], qr/Not found in/, "failed repository") ;
like($info_messages[2][0], qr~Found in '.*?/dir_1~, "found in repository") ;
like($info_messages[3][0], qr~Found in '.*?/dir_2~, "found in repository") ;
like($info_messages[4][0], qr~Found in '.*?/dir_3~, "found in repository") ;

#----------------------------------------------------------------------

@info_messages = () ;
$located_file = $locator->Find(FILES => ['file_a'], VERBOSE => 0) ;
is(@info_messages, 0, "no messages") or diag DumpTree \@info_messages;

#----------------------------------------------------------------------

$located_file = $locator->Find('/file_a') ;
is(@warn_messages, 1, "warn messages") ;
like($warn_messages[0][0], qr~verbose test: passed absolute file path '/file_a'~, "full path warning") ;

#----------------------------------------------------------------------

throws_ok
	{
	$locator->Find({}) ;
	} qr~verbose test: single argument must be scalar~, "argument not scalar" ;
	
is(@die_messages, 1, "dying with one message") ;

#----------------------------------------------------------------------

throws_ok
	{
	$locator->Find(FILES => ['file_a'], VERBOSE => 1, AT_FILE => 'some file', AT_LINE => 'some line') ;
	}  qr~not called in scalar context at 'some file:some line'~, "AT_FILE ok" ;

}

#----------------------------------------------------------------------

{
local $Plan = {'INTERACTION ERROR' => 1} ;

my $temporary_directory  = create_directories($test_directory_structure) ;

my $base = $temporary_directory->base() ;

my $locator = new File::Find::Repository
				(
				NAME            => 'verbose test',
				VERBOSE         => 1,
				REPOSITORIES =>["$base"],
				) ;

use IO::File;

my $current_fh = select ;

my $fh = new IO::File; # not opened
select $fh ;

throws_ok
	{
	warning_is
		{
		my $located_file = $locator->Find('file_a') ;
		}
		qr/print() on unopened filehandle/, 'unopen filehandle' ;
	}
	qr/Can't print!/, 'print failed' ;
	
select $current_fh ;
}

#----------------------------------------------------------------------

{
local $Plan = {'INTERACTION OVERRIDE' => 11} ;

my (@info_messages, @warn_messages, @die_messages);

my $info = sub {push @info_messages, [@_]} ;
my $warn = sub {push @warn_messages, [@_]} ;
my $die = sub {push @die_messages, [@_]; die @_} ;
	
my $temporary_directory  = create_directories($test_directory_structure) ;

my $base = $temporary_directory->base() ;

my $locator = new File::Find::Repository
				(
				NAME            => 'verbose test',
				VERBOSE         => 1,
				REPOSITORIES =>
					[
					"$base",
					"$base/dir_1",
					"$base/dir_2",
					"$base/dir_3",
					],
				) ;

my @interraction_subs = 
	(
	INTERACTION  => 
		{
		INFO  => $info,
		WARN  => $warn,
		DIE   => $die,
		},
	) ;

use Data::TreeDumper ;
my $located_file = $locator->Find(FILES => ['file_a'], @interraction_subs) ;
is(@info_messages, 5, "info messages") or diag DumpTree \@info_messages;
like($info_messages[0][0], qr/Searching for 'file_a'/, "search header") ;
like($info_messages[1][0], qr/Not found in/, "failed repository") ;
like($info_messages[2][0], qr~Found in '.*?/dir_1~, "found in repository") ;
like($info_messages[3][0], qr~Found in '.*?/dir_2~, "found in repository") ;
like($info_messages[4][0], qr~Found in '.*?/dir_3~, "found in repository") ;

#----------------------------------------------------------------------

@info_messages = () ;
$located_file = $locator->Find(FILES => ['file_a'], VERBOSE => 0, @interraction_subs) ;
is(@info_messages, 0, "no messages") or diag DumpTree \@info_messages;

#----------------------------------------------------------------------

$located_file = $locator->Find(FILES => ['/file_a'], @interraction_subs) ;
is(@warn_messages, 1, "warn messages") ;
like($warn_messages[0][0], qr~verbose test: passed absolute file path '/file_a'~, "full path warning") ;

#----------------------------------------------------------------------

throws_ok
	{
	$locator->Find(FILES => ['a'], @interraction_subs) ;
	} qr~not called in scalar contex~, "not called in scalar contex" ;
	
is(@die_messages, 1, "dying with one message") ;

}

#----------------------------------------------------------------------

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

