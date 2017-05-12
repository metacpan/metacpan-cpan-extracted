#!/usr/bin/perl

use warnings;
use strict;
use Games::Freelancer::UTF;

sub offsetFloatarray { #move a position by an array
	my $array=shift;
	my $offset=shift;
	my @a = unpack("f*",$array);
	$a[0]-=$offset;#Move only the x value.
	print @a,"\n";
	return pack("f*",@a);
}

sub clearstring { #Clears up a string.
	my $str=shift;
	return substr($str,0,index($str,"\0"));
}

unless (@ARGV) {
	print "Fixes up a bug from the milkshape export plugin (Hardpoints not centered) \nUsage: $0 Model.cmp\n";
	exit;
}

my $file=$ARGV[0];
open FH, $file;
binmode FH;
my $tree=UTFread(do {local $/;<FH>});
close FH;

my $rootobj = clearstring($tree->{"\\"}->{"Cmpnd"}->{"Root"}->{"File name"});
die "Can't find RootObject Name in $file\n" unless $rootobj;
#Get the position of HPMount, normally for those modules it should be at x = 0 , but somehow the model is right but the hardpoints are at x = 0,15.
my $root=join " ",$tree->{"\\"}->{$rootobj}->{Hardpoints}->{"Fixed"}->{"HpMount"}->{Position} or die "Can't find position for HpMount";
my @offset = unpack ("f*",$root);
if ($offset[0]) {
	#Get all included models:
	foreach my $entr (grep /\.3db/,keys %{$tree->{"\\"}}) {
		print "Moving in $entr\n";
		foreach (keys %{$tree->{"\\"}->{$entr}->{Hardpoints}->{"Fixed"}}) { #Move fixed ones.
			print "Moving '$_'\n";
			$tree->{"\\"}->{$entr}->{Hardpoints}->{"Fixed"}->{$_}->{Position}=offsetFloatarray($tree->{"\\"}->{$entr}->{Hardpoints}->{"Fixed"}->{$_}->{Position},$offset[0])
		}
		foreach (keys %{$tree->{"\\"}->{$entr}->{Hardpoints}->{"Revolute"}}) { #Move revolute ones.
			print "Moving '$_'\n";
			$tree->{"\\"}->{$entr}->{Hardpoints}->{"Revolute"}->{$_}->{Position}=offsetFloatarray($tree->{"\\"}->{$entr}->{Hardpoints}->{"Revolute"}->{$_}->{Position},$offset[0])
		}
	}
	rename $file,"$file.bak";
	open FH, ">$file";
	binmode FH;
	print FH UTFwriteUTF($tree); #And write again
	close FH;
}
else {
	print "No need for me to move it around, its already at x=0\n";
}

