#!/usr/local/bin/perl -w

use strict ;

use File::Slurp ;
use Carp ;
use Test::More ;

plan( tests => 1 ) ;

my $proc_file = "/proc/$$/auxv" ;

SKIP: {

	unless ( -r $proc_file ) {

		skip "can't find pseudo file $proc_file", 1 ;
	}

	test_pseudo_file() ;
}

sub test_pseudo_file {

	my $data_do = do{ local( @ARGV, $/ ) = $proc_file; <> } ;

#print "LEN: ", length $data_do, "\n" ;

	my $data_slurp = read_file( $proc_file ) ;
#print "LEN2: ", length $data_slurp, "\n" ;
#print "LEN3: ", -s $proc_file, "\n" ;

	is( $data_do, $data_slurp, 'pseudo' ) ;
}
