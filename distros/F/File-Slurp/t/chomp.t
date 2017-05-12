
use strict ;
use warnings ;

use lib qw(t) ;

use File::Slurp qw( read_file write_file ) ;
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
		name	=> 'read_file - chomp',
		sub	=> \&read_file,
		args	=> [
				$file,
				{
					'chomp'	=> 1,
					array_ref => 1
				},
		],
		pretest	=> sub {
			my( $test ) = @_ ;
			write_file( $file, $existing_data ) ;
		},
		posttest => sub {
			my( $test ) = @_ ;
			$test->{ok} = eq_array(
				$test->{result},
				[$existing_data =~ /^(.+)\n/gm]
			) ;
		},
	},
] ;

test_driver( $tests ) ;

unlink $file ;

exit ;
