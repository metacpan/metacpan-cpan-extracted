#!/usr/local/bin/perl -w

use strict ;
use File::Slurp ;

use Carp ;
use Socket ;
use Symbol ;
use Test::More tests => 6 ;

my $data = <<TEXT ;
line 1
more text
TEXT

foreach my $file ( qw( stdin STDIN stdout STDOUT stderr STDERR ) ) {

	write_file( $file, $data ) ;
	my $read_buf = read_file( $file ) ;
	is( $read_buf, $data, 'read/write of file [$file]' ) ;

	unlink $file ;
}
