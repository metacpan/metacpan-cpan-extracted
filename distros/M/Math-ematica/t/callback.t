#                              -*- Mode: Perl -*- 
# $Basename: callback.t $
# $Revision: 1.6 $
# Author          : Ulrich Pfeifer
# Created On      : Sat Dec 20 17:04:10 1997
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Sat Feb 14 13:16:38 1998
# Language        : CPerl
# Update Count    : 301
# Status          : Unknown, Use with caution!
# 
# (C) Copyright 1997, Ulrich Pfeifer, all rights reserved.
# 
# 

use vars qw($test);

sub test (& ) {
  my $arg = shift;
  my $result = eval {&$arg};

  $test++;
  print "$test: $@\n" if $@;
  print 'not ' if $@ or not $result;
  print 'ok ', $test, "\n";
}

BEGIN {
  my $num_tests = 6;
  open(SELF, "< $0") or die "Could not open '$0': $!\n";
  while (defined ($_ = <SELF>)) {
    $num_tests++ if /^test/;
  }
  $| = 1;
  print "1..$num_tests\n";
}

use Math::ematica qw(:PACKET :FUNC);

my $ml;

test {$ml = new Math::ematica '-linklaunch', '-linkname', 'math -mathlink'};
test {$ml->NextPacket == INPUTNAMEPKT};

test {$ml->register('AddTwo', sub { print "ok ", ++$test, "\n"; $_[0]+$_[1]}, 'Integer', 'Integer')};
test {$ml->call([symbol 'AddTwo',2,  3]) ==  5};
test {$ml->call([symbol 'AddTwo',12, 3]) == 15};

test {$ml->register('Hello', sub { print "ok ", ++$test, "\n"; "Hello from Perl"}, 'String')};
test {$ml->call([symbol 'Hello','Grettings']) eq "Hello from Perl"};

test {$ml->register('Ping', sub { print "ok ", ++$test, "\n"; "Pong"})};
test {$ml->call([symbol 'Ping']) eq "Pong"};

test {$ml->register('Foo', sub { print "ok ", ++$test, "\n"; join ':', @_}, undef, undef)};
test {$ml->call([symbol 'Foo', '1', 1]) eq "1:1"};
test {$ml->call([symbol 'Foo', '1', 'Ping']) eq "1:Ping"};

