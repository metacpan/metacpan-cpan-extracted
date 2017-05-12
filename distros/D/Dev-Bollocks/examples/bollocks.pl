#!/usr/bin/perl -w

use lib 'lib';
use lib '../lib';
use Dev::Bollocks;
use strict;

my $count;
foreach (3..5)
  {
  $count = Dev::Bollocks->new()->class($_);
  print "You can have ",$count," different bollocks with $_ words.\n";
  }

my @phrases = (
  "So, let's ", 'We can ', 'We should ', 'Our mission is to ',
  'Our job is to ', 'Your job is to ', 'And next we ', 'We better ',
  'All of us plan to ', 'It is important to ', 'We were told to ',
  'Our mission is to ', 'According to our plan we ');
my $i = 0; my $last = ""; my $phrase = ""; my $p;
while ($i++ < $count)
  {
  while ($phrase eq $last)
    {
    $phrase = $phrases[int(rand(scalar @phrases))];
    }
  $p = $phrase . Dev::Bollocks->rand( int(rand(3) + 3)).".\n";	# 3 .. 5
  print $p if length($p) < 78;
  $last = $phrase;
  }
