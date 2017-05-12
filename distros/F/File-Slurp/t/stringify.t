#!perl -T

use strict;

use Test::More;
use File::Slurp;
use IO::Handle ;
use UNIVERSAL ;

plan tests => 3 ;

my $path = "data.txt";
my $data = "random junk\n";

# create an object with an overloaded path

my $obj = FileObject->new( $path ) ;

isa_ok( $obj, 'FileObject' ) ;
is( "$obj", $path, "object stringifies to path" );

write_file( $obj, $data ) ;

my $read_text = read_file( $obj ) ;
is( $data, $read_text, 'read_file of stringified object' ) ;

unlink $path ;

exit ;

# this code creates the object which has a stringified path

package FileObject;

use overload
	q[""]	=> \&stringify,
	fallback => 1 ;

sub new {
	return bless { path => $_[1] }, $_[0]
}

sub stringify {
	return $_[0]->{path}
}
