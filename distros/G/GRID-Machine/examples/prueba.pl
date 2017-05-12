#!/usr/local/bin/perl -w
use strict;
use GRID::Machine;

my $machine = shift || $ENV{GRID_REMOTE_MACHINE};
my $m = GRID::Machine->new( host => $machine );

$m->eval( "use POSIX qw( uname )" );
my $remote_uname = $m->eval( "uname()" )->results;
print "@$remote_uname\n";

# We can pass arguments
$m->eval( q{
    open FILE, '> /tmp/foo.txt'; 
    print FILE shift; 
    close FILE;
  },
  "Hello, world!" 
);

# We can pre-compile stored procedures
$m->compile( slurp_file => q{
  my $filename = shift;
  my $FILE;
  local $/ = undef; 
  open $FILE, "< /tmp/foo.txt";
  $_ = <$FILE>;
  close $FILE;
  return $_;
}
);

my @files = $m->eval('glob("/tmp/*.txt")');
foreach my $file ( @files ) {
  my $content = $m->call( "slurp_file", $file );
  print $content->result."\n";
}
