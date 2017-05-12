
use strict ;
use warnings ;

use lib qw(t) ;

use File::Slurp qw( :edit read_file write_file ) ;
use Test::More ;

use TestDriver ;

my $file = 'edit_file_data' ;

my $existing_data = <<PRE ;
line 1
line 2
more
foo
bar
junk here and foo
last line
PRE

my $tests = [
	{
		name	=> 'edit_file - no-op',
		sub	=> \&edit_file,
		pretest	=> sub {
			my( $test ) = @_ ;
			write_file( $file, $existing_data ) ;
			$test->{args} = [
				sub {},
				$file
			] ;
			$test->{expected} = $existing_data ;
		},
		posttest => sub { $_[0]->{result} = read_file( $file ) },
	},
	{

		name	=> 'edit_file - s/foo/bar/',
		sub	=> \&edit_file,
		pretest	=> sub {
			my( $test ) = @_ ;
			write_file( $file, $existing_data ) ;
			$test->{args} = [
				sub { s/foo/bar/g },
				$file
			] ;
			( $test->{expected} = $existing_data )
				=~ s/foo/bar/g ;
		},
		posttest => sub { $_[0]->{result} = read_file( $file ) },
	},
	{

		name	=> 'edit_file - upper first words',
		sub	=> \&edit_file,
		pretest	=> sub {
			my( $test ) = @_ ;
			write_file( $file, $existing_data ) ;
			$test->{args} = [
				sub { s/^(\w+)/\U$1/gm },
				$file
			] ;
			( $test->{expected} = $existing_data )
				=~ s/^(\w+)/\U$1/gm ;
		},
		posttest => sub { $_[0]->{result} = read_file( $file ) },
	},
	{
		name	=> 'edit_file_lines - no-op',
		sub	=> \&edit_file_lines,
		pretest	=> sub {
			my( $test ) = @_ ;
			write_file( $file, $existing_data ) ;
			$test->{args} = [
				sub {},
				$file
			] ;
			$test->{expected} = $existing_data ;
		},
		posttest => sub { $_[0]->{result} = read_file( $file ) },
	},
	{

		name	=> 'edit_file - delete foo lines',
		sub	=> \&edit_file_lines,
		pretest	=> sub {
			my( $test ) = @_ ;
			write_file( $file, $existing_data ) ;
			$test->{args} = [
				sub { $_ = '' if /foo/ },
				$file
			] ;
			( $test->{expected} = $existing_data )
				=~ s/^.*foo.*\n//gm ;
		},
		posttest => sub { $_[0]->{result} = read_file( $file ) },
	},
] ;

test_driver( $tests ) ;

unlink $file ;

exit ;
