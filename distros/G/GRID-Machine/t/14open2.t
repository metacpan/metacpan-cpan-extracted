#!/usr/local/bin/perl -w
use strict;
sub findVersion {
  my $pv = `perl -v`;
  my ($v) = $pv =~ /v(\d+\.\d+)\.\d+/;

  $v ? $v : 0;
}
use Test::More tests => 20;

BEGIN { use_ok('GRID::Machine', 'is_operative') };

my $test_exception_installed;
BEGIN {
  $test_exception_installed = 1;
  eval { require Test::Exception };
  $test_exception_installed = 0 if $@;
}

my $host = $ENV{GRID_REMOTE_MACHINE} || '';

SKIP: {
    skip "Remote not operative or Test::Exception isn't installed or no linux", 19 unless 
      $test_exception_installed and  $host && is_operative('ssh', $host) and ( $^O =~ /linux|darwin/);

    my $m;
    Test::Exception::lives_ok { 
      $m = GRID::Machine->new(host => $host);
    } 'No fatals creating a GRID::Machine object';

    my $i;
    my $pid;
    my $RDR;
    my $WTR;
   
    Test::Exception::lives_ok { $RDR = IO::Handle->new(); } "No fatals creating a IO::Handle for reading";
    Test::Exception::lives_ok { $WTR = IO::Handle->new(); } "No fatals creating a IO::Handle for writing";
    Test::Exception::lives_ok { $pid = $m->open2($RDR, $WTR, 'sort -n'); } "No fatals opening a bidirectional pipe and launching a remote process";
    for($i=10; $i>=0;$i--) {
      Test::Exception::lives_ok { $WTR->print("$i\n"); } "No fatals sending to output pipe $i";
    }
    Test::Exception::lives_ok { $WTR->close(); } 'No fatals closing output pipe';
    
    my @lines;
    my $result = [ "0\n", "1\n", "2\n", "3\n", "4\n", "5\n", "6\n", "7\n", "8\n", "9\n", "10\n" ];
    
    Test::Exception::lives_ok { (@lines = <$RDR>); } "No fatals receiving from input pipe";
    Test::Exception::lives_ok { $RDR->close(); } 'No fatals closing input pipe';
    is_deeply(\@lines, $result, "The answer received by input pipe is the same as the expected result");

} # end SKIP block
