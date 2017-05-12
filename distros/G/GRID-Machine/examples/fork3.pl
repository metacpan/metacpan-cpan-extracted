#!/usr/bin/perl -w
use strict;
use GRID::Machine qw(is_operative);
use Data::Dumper;

my $host = $ENV{GRID_REMOTE_MACHINE} or die "Set env variable GRID_REMOTE_MACHINE\n";;
my $debug = @ARGV ? 1234 : 0;

my $machine = GRID::Machine->new( 
      host => $host,
      uses => [ 'Sys::Hostname' ],
      debug => $debug,
      report => 'report',
      cleanup => 0,
   );

my $s = $machine->eval(q{ 
  gprint "Father: $$ tempdir = ".File::Spec->tmpdir."\n"; 
  SERVER->remotelog( "Starting Child");
});

my $p = $machine->fork( q{
   print "stdout: Hello from process $$. args = (@_)\n";
   print STDERR "stderr: Hello from process $$\n";

   open my $F, ">child.log";
     print $F "child.log: Hello from process $$\n";
   close($F);

   use List::Util qw{sum};
   return sum(@_);
 },
 result => '/tmp/rperl/result.log',
 args   => [ 1..4 ],
);

my $r = $machine->waitpid($p, 0);

print 'PID: ',Dumper($r),"\n";

