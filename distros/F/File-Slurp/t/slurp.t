#!/usr/local/bin/perl -w -T

use strict ;
use File::Slurp qw( write_file slurp ) ;

use Test::More tests => 1 ;

my $data = <<TEXT ;
line 1
more text
TEXT

my $file = 'xxx' ;

write_file( $file, $data ) ;
my $read_buf = slurp( $file ) ;
is( $read_buf, $data, 'slurp alias' ) ;

unlink $file ;
