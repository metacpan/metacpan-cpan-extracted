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
      cleanup => 0,     # keep ~/report file
   );

my $p = $machine->fork( q{
   print "stdout: Hello from process $$. args = (@_)\n";
   print STDERR "stderr: Hello from process $$\n";

   use List::Util qw{sum};
   return sum(@_);
 },
 stdout => 'chuchu.out',
 stderr => 'chuchu.err',
 stdin  => '/dev/null',
 result => 'result.log',
 args   => [ 1..4 ],
);

my $r = $machine->waitpid($p);

print 'PID: ',Dumper($r),"\n";
