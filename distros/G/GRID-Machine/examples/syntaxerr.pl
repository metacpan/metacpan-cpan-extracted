#!/usr/local/bin/perl -w
# There is one error at line X1
use strict;
use GRID::Machine;

my $machine = GRID::Machine->new( host => 'casiano@orion.pcg.ull.es' );

$machine->eval( "use POSIX qw( uname )" );
my $remote_uname = $machine->eval( "uname()" )->results;
print "@$remote_uname\n";

# We can pass arguments
$machine->eval( q{
    open FILE, '> /tmp/foo.txt'; 
    print FILE shift; 
    close FILE;
  },
  "Hello, world!" 
);

# We can pre-compile stored procedures
my $result = $machine->sub( 
  read_all => q{
#line 25  err1.pl 
    my $filename = shift;
    my $FILE;
    local $/ ) undef; # line X1 <-- error!!!
    open $FILE, "< /tmp/foo.txt";
    $_ = <$FILE>;
    close $FILE;
    return $_;
  },
);

die $result->errmsg unless $result->type eq 'OK';

my @files = $machine->eval('glob("/tmp/*.txt")');
foreach my $file ( @files ) {
  # Remote call: an GRID::Machine::Result object is returned
  my $content = $machine->read_all($file )->result;
  print "$content\n";
}
