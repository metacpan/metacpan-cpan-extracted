#                              -*- Mode: Perl -*- 
# $Basename: basic.t $
# $Revision: 1.11 $
# Author          : Ulrich Pfeifer
# Created On      : Sat Dec 20 17:04:10 1997
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Tue Apr 26 16:00:30 2005
# Language        : CPerl
# Update Count    : 118
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

use Math::ematica qw(:PACKET :TYPE);

my $ml;

test {$ml = new Math::ematica '-linklaunch', '-linkname', 'math -mathlink'};
test {$ml->NextPacket == INPUTNAMEPKT};

test {$ml->PutFunction('Sin', 1)};
test {$ml->PutDouble(0)};
test {$ml->EndPacket};
test {$ml->Flush};
test {$ml->NewPacket};
test {$ml->NextPacket == RETURNPKT};
test {my $r = $ml->GetNext; $r == MLTKREAL or $r == MLTKINT};
test {$ml->GetDouble == 0};


test {$ml->PutFunction('Table', 2)};
test {$ml->PutFunction('Sin', 1)};
test {$ml->PutSymbol('x')};
test {$ml->PutFunction('List',4)};
test {$ml->PutSymbol('x')};
test {$ml->PutDouble(0)};
test {$ml->PutDouble(1)};
test {$ml->PutDouble(0.5)};
test {$ml->EndPacket};
test {$ml->Flush};

test {$ml->NewPacket};
test {$ml->NextPacket == RETURNPKT};
test {$ml->GetNext == MLTKFUNC};
test { my ($name, $nargs) = $ml->GetFunction; $$name eq 'List' and $nargs == 3};

test {my $r = $ml->GetNext; $r == MLTKREAL or $r == MLTKINT};
test {$ml->GetNext == MLTKREAL};
test {$ml->GetNext == MLTKREAL};

test {$ml->PutFunction('Table', 2)};
test {$ml->PutFunction('Sin', 1)};
test {$ml->PutSymbol('x')};
test {$ml->PutFunction('List',4)};
test {$ml->PutSymbol('x')};
test {$ml->PutDouble(0)};
test {$ml->PutDouble(1)};
test {$ml->PutDouble(0.5)};
test {$ml->EndPacket};
test {$ml->Flush};

test {$ml->NewPacket};
test {$ml->NextPacket == RETURNPKT};
test {$ml->GetNext == MLTKFUNC};
test { my @t = $ml->GetRealList; @t == 3 };

test { $ml->ErrorMessage =~ /everything \s+ ok/ix };

# ExportString[Plot[Tan[x], {x, -3, 3}],"eps"]
test {$ml->PutFunction('ExportString', 2)};
test {$ml->PutFunction('Plot', 2)};
test {$ml->PutFunction('Tan', 1)};
test {$ml->PutSymbol('x')};
test {$ml->PutFunction('List',3)};
test {$ml->PutSymbol('x')};
test {$ml->PutDouble(-3)};
test {$ml->PutDouble(3)};
test {$ml->PutString("eps")};
test {$ml->EndPacket};
test {$ml->Flush};

test {$ml->NewPacket};
test {$ml->NextPacket == DISPLAYPKT};
test {$ml->GetNext == MLTKSTR};
test {length($ml->GetByteString) == 0};

test {$ml->NextPacket == DISPLAYPKT};
test {$ml->GetNext == MLTKSTR};
test {$ml->GetByteString =~ /^%!/};
