#!/usr/bin/perl --
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Math::Permute::Array.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;
#this requirement is only to get the good INC
use File::Basename;

#to be able to run this example from every where
BEGIN{my $dir= dirname($0); push @INC,"$dir/../lib";}
use Math::Permute::Array;


print "permutation with direct call to Permutate\n";
my $i;
my @array = (1,2,3);
foreach $i (0..5){
  my @tmp = @{Math::Permute::Array::Permute($i,\@array)};
  print "@tmp\n";
}

print "permutation with counter\n";
my $p = new Math::Permute::Array(\@array);
foreach $i (0..$p->cardinal()-1){
  my @tmp = @{$p->permutation($i)};
  print "@tmp\n";
}

print "permutation with next\n";
$p = new Math::Permute::Array(\@array);
my @tmp = @{$p->cur()};
print "@tmp\n";
foreach $i (1..$p->cardinal()-1){
  @tmp = @{$p->next()};
  print "@tmp\n";
}

print "permutation with prev\n";
my $tmp=\@tmp;
while(defined $tmp){
  @tmp = @{$tmp};
  print "@tmp\n";
  $tmp = $p->prev();
}

print "Apply a function on all permutations\n";
Math::Permute::Array::Apply_on_perms { print "@_\n"} \@array;
