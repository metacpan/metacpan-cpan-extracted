#!/usr/local/bin/perl -w
# Works with ptkdb
use strict;
use IPC::PerlSSH;

my $ips = IPC::PerlSSH->new( 
  #Host => 'casiano@orion.pcg.ull.es',
  #Command => 'ssh -X casiano@orion.pcg.ull.es perl -d:ptkdb',
  Command => 'ssh -X localhost perl -d:ptkdb',
);

$ips->eval( "use POSIX qw( uname )" );
my @remote_uname = $ips->eval( "uname()" );

print "@@remote_uname\n";
