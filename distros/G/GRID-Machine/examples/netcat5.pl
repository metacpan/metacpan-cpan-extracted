#!/usr/local/bin/perl -w
use strict;
use GRID::Machine;

my $hostport = shift || $ENV{GRID_REMOTE_DEBUG} || usage();
$hostport =~ m{^([\w.]+):(\d+)$} or usage();
my $host = $1;
my $port = $2;

my $machine = GRID::Machine->new(
   host => $host,
   debug => $port,
);

print $machine->eval(q{ 
  system('ls');
  print %ENV,"\n";
});

sub usage {
  warn "Usage:\n$0 host:port\n";
  exit(1);
}

__END__
