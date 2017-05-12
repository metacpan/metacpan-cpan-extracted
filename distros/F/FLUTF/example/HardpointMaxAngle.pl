#!/usr/bin/perl

use warnings;
use strict;
use Games::Freelancer::UTF;

#I used this script for my TNG Rebalanced 2.79. Cause ships that can't shoot behind them are not equally matched with those who can.

sub maxAngle { #Writes the maximal angle into binary.
	my $array=shift;
	my $offset=shift;
	my @a = unpack("f*",$array);
	$a[0]=$offset;
	print @a,"\n";
	return pack("f*",@a);
}

unless (@ARGV) {
	print "Makes all Hardpoints have the maximum fire radius.\nUsage: $0 Model.cmp\n";
	exit;
}

#Read the file.
my $file=$ARGV[0];
open FH, $file;
binmode FH;
my $tree=UTFread(do {local $/;<FH>});
close FH;

foreach my $entr (grep /\.3db/,keys %{$tree->{"\\"}}) { #Go through all .3db files in the .cmp.
	next unless $tree->{"\\"}->{$entr}->{Hardpoints}; #No hardpoints in this one
	next unless $tree->{"\\"}->{$entr}->{Hardpoints}->{"Revolute"}; #No Revolute hardpoints here.
	foreach my $hp (keys %{$tree->{"\\"}->{$entr}->{Hardpoints}->{"Revolute"}}) { #For all Hardpoints:
		#Overwrite it wit the maximun amount (2pi) in both directions, this way they won't rotate back.
		$tree->{"\\"}->{$entr}->{Hardpoints}->{"Revolute"}->{$hp}->{Max}=maxAngle($tree->{"\\"}->{$entr}->{Hardpoints}->{"Revolute"}->{$hp}->{Max},6.283185307179586476925286766559);
		$tree->{"\\"}->{$entr}->{Hardpoints}->{"Revolute"}->{$hp}->{Min}=maxAngle($tree->{"\\"}->{$entr}->{Hardpoints}->{"Revolute"}->{$hp}->{Min},-6.283185307179586476925286766559);
	}
}
rename $file,"$file.bak"; #Save as .bak.
open FH, ">$file";
binmode FH;
print FH UTFwriteUTF($tree); #Write the tree again.
close FH;
