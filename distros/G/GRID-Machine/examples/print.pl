#!/usr/local/bin/perl -w
use strict;
use GRID::Machine;

my $ips = GRID::Machine->new( host => 'casiano@orion.pcg.ull.es',
  sendstdout => 1,
);

my $p = $ips->eval( q{
    use vars qw($a);
    $a = caller(0);
    print "$a\n";
    warn "Be careful!\n";
    $a;
  }
);
print $p->result,"\n";
print "ORION STDOUT: ",$p->rstdout,"\n";
print "ORION STDERR: ",$p->rstderr,"\n";
