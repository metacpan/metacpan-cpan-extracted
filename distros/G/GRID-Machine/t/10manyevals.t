#!/usr/local/bin/perl -w
use strict;
sub findVersion {
  my $pv = `perl -v`;
  my ($v) = $pv =~ /v(\d+\.\d+)\.\d+/;

  $v ? $v : 0;
}
use Test::More tests => 2;
BEGIN { use_ok('GRID::Machine', qw(is_operative qc)) };

my $host = $ENV{GRID_REMOTE_MACHINE} || '';

SKIP: {
  skip "Remote not operative", 1 unless $host and  ($^O =~ /darwin|n[ui]x/) && is_operative('ssh', $host);

########################################################################

  my $machine = GRID::Machine->new( 
        host => $host,
        cleanup => 1,
        sendstdout => 1,
        startdir =>  '/tmp/tutu',
     );

  my $s1 = $machine->eval(q{ print "one\nTwo\n" })->stdout;
  my $s2 = $machine->eval(q{ print "one\nTwo\n" })->stdout;

  is($s2, "one\nTwo\n", "not accumulative output");

} # end SKIP block
