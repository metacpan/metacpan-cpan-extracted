#!perl
use strict;
use Test::More;
use File::Slurp;

use IO::Handle ;

use UNIVERSAL ;

plan tests => 4;

my $path = "data.txt";
my $data = "random junk\n";

# create an object
my $obj = FileObject->new($path);
isa_ok( $obj, 'FileObject' );
is( "$obj", $path, "check that the object correctly stringifies" );

my $is_glob = eval{ $obj->isa( 'GLOB' ) } ;
#print "GLOB $is_glob\n" ;

my $is_io = eval{ $obj->isa( 'IO' ) } ;
#print "IO $is_io\n" ;

my $io = IO::Handle->new() ;
#print "IO2: $io\n" ;

my $is_io2 = eval{ $io->isa( 'GLOB' ) } ;
#print "IO2 $is_io2\n" ;

open( FH, "<$0" ) or die "can't open $0: $!" ;

my $io3 = *FH{IO} ;
#print "IO3: $io3\n" ;

my $is_io3 = eval{ $io3->isa( 'IO' ) } ;
#print "IO3 $is_io3\n" ;

my $io4 = *FH{GLOB} ;
#print "IO4: $io4\n" ;

my $is_io4 = eval{ $io4->isa( 'GLOB' ) } ;
#print "IO4 $is_io4\n" ;


SKIP: {
    # write something to that file
    open(FILE, ">$obj") or skip 4, "can't write to '$path': $!";
    print FILE $data;
    close(FILE);

    # pass it to read_file()
    my $content = eval { read_file($obj) };
    is( $@, '', "passing an object to read_file()" );
    is( $content, $data, "checking that the content matches the data" );
}

unlink $path;


# the following mimics the parts from Path::Class causing 
# problems with File::Slurp
package FileObject;
use overload
    q[""] => \&stringify, fallback => 1;

sub new {
    return bless { path => $_[1] }, $_[0]
}

sub stringify {
    return $_[0]->{path}
}

