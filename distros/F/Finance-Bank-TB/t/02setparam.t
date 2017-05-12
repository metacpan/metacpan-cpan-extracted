#!/usr/bin/perl -w

BEGIN { $| = 1; print "1..2\n"; }

use Finance::Bank::TB;

sub do_test
{
  my ($num, $key, $expect, $cs ) = @_;

  print "EXPECT:   $expect\n";

  $myob1 = Finance::Bank::TB->new('002',$key);

  my $result = $myob1->cs($cs);
  print "RESULT:   $result\n";
  print "not " unless ($result eq $expect);
  print "ok $num\n";
  return();
}

print "If the following results don't match, there's something wrong.\n\n";

do_test("1", "12345678" , "308","308");

do_test("2", "87654321" , "400","400");

