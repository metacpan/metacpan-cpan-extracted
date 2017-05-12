#!/usr/local/bin/perl -w
use strict;
use GRID::Machine;

my $machine = GRID::Machine->new( 
      host => 'casiano@orion.pcg.ull.es',
      cleanup => 0,
   );

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
$machine->sub( 
  read_all => q{
#line  __LINE__ __FILE__
    my $filename = shift;
    my $FILE;
    local $/ = undef; 
    open $FILE, "< /tmp/foo.txt";
    $_ = <$FILE>;
    close $FILE;
    return $_;
  },
);

my @files = $machine->eval('glob("/tmp/*.txt")');
foreach my $file ( @files ) {
  # Remote call: an GRID::Machine::Result object is returned
  my $content = $machine->read_all($file )->result;
  print "$content\n";
}

$machine->eval( q{
    warn "Esto queda en el fichero .err remoto\n";
  }
);
