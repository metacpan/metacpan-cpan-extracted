#                              -*- Mode: Perl -*- 
# $Basename: call.t $
# $Revision: 1.6.1.5 $
# Author          : Ulrich Pfeifer
# Created On      : Sat Dec 20 17:04:10 1997
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Tue Apr 26 17:31:02 2005
# Language        : CPerl
# Update Count    : 210
# Status          : Unknown, Use with caution!
# 
# (C) Copyright 1997, Ulrich Pfeifer, all rights reserved.
# 
# 

{
  my $test;

  sub test (& ) {
    my $arg = shift;
    my $result = eval {&$arg};

    $test++;
    print "$test: $@\n" if $@;
    print 'not ' if $@ or not $result;
    print 'ok ', $test, "\n";
  }
}

BEGIN {
  my $num_tests = 0;
  open(SELF, "< $0") or die "Could not open '$0': $!\n";
  while (defined ($_ = <SELF>)) {
    $num_tests++ if /^test/;
  }
  $| = 1;
  print "1..$num_tests\n";
}

use Math::ematica qw(:PACKET :TYPE :FUNC);

my $ml;

test {$ml = new Math::ematica '-linklaunch', '-linkname', 'math -mathlink'};
test {$ml->NextPacket == INPUTNAMEPKT};
my $sin;
test {$sin = symbol 'Sin'};
test {$ml->send_packet([$sin, 0.0])};

test {$ml->NewPacket};
test {$ml->NextPacket == RETURNPKT};

test { $ml->read_packet == 0 };

my $tab;
test {$tab = symbol 'Table'};
my $x;
test {$x = symbol 'x'};
my $list;
test {$list = symbol 'List'};

test {$ml->send_packet([$tab, [$sin, $x], [$list, $x, 0, 1, 0.5]])};


test {$ml->NewPacket};
test {$ml->NextPacket == RETURNPKT};

test {my $array = $ml->read_packet; @$array == 3};

test {int($ml->call([symbol 'Sin', 3.14159265358979/2])*1000) == 1000};

$ml->install('Sin',1);

test { Sin(0) < 0.001 and Sin(0) > -0.001};
test { Sin(0) == 0};

$ml->install('Pi');
$ml->install('N',1);
$ml->install('Divide',2);

test { Sin(Divide(Pi(),2.0)) == 1.0 };

test {
  $ml->call(
            [symbol "ExportString",
             [symbol "Plot",
              [
               symbol "Tan",
               symbol "x"
              ],
              [
               symbol "List",
               symbol "x",
               -3,
               3
              ],
             ],
             "eps"
            ]
           ) =~ /^%!/
         };
