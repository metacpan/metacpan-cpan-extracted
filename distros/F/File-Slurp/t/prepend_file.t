
use strict ;
use warnings ;

use lib qw(t) ;

use File::Slurp qw( read_file write_file prepend_file ) ;
use Test::More ;

use TestDriver ;

my $file = 'prepend_file' ;
my $existing_data = <<PRE ;
line 1
line 2
more
PRE

my $tests = [
	{
		name	=> 'prepend null',
		sub	=> \&prepend_file,
		prepend_data	=> '',
		pretest	=> sub {
			my( $test ) = @_ ;
			write_file( $file, $existing_data ) ;
			my $prepend_data = $test->{prepend_data} ;
			$test->{args} = [
				$file,
				$prepend_data,
			] ;
			$test->{expected} = "$prepend_data$existing_data" ;
		},
		posttest => sub { $_[0]->{result} = read_file( $file ) },
	},
	{
		name	=> 'prepend line',
		sub	=> \&prepend_file,
		prepend_data => "line 0\n",
		pretest	=> sub {
			my( $test ) = @_ ;
			write_file( $file, $existing_data ) ;
			my $prepend_data = $test->{prepend_data} ;
			$test->{args} = [
				$file,
				$prepend_data,
			] ;
			$test->{expected} = "$prepend_data$existing_data" ;
		},
		posttest => sub { $_[0]->{result} = read_file( $file ) },
	},
	{
		name	=> 'prepend partial line',
		sub	=> \&prepend_file,
		prepend_data => 'partial line',
		pretest	=> sub {
			my( $test ) = @_ ;
			write_file( $file, $existing_data ) ;
			my $prepend_data = $test->{prepend_data} ;
			$test->{args} = [
				$file,
				$prepend_data,
			] ;
			$test->{expected} = "$prepend_data$existing_data" ;
		},
		posttest => sub { $_[0]->{result} = read_file( $file ) },
	},
] ;

test_driver( $tests ) ;

unlink $file ;

exit ;
