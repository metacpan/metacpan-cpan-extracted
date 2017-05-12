#!/usr/bin/perl

use warnings;
use strict;
use Games::Freelancer::UTF;

#The strings in the file end with \0, the keys don't so we have cut it off:
sub clearstring {
	my $str=shift;
	return substr($str,0,index($str,"\0"));
}


unless (@ARGV) {
	print "Copies all Hardpoints from one file to another\nUsage: $0 Sourcefile, Targetfile [Targetfile ...]\n";
	exit;
}

#Read the source:
my $file=shift @ARGV;
open FH, $file or die "Can't open source $file: $!\n";
binmode FH;
my $tree=UTFread(do {local $/;<FH>});
close FH;

#Extract the hardpoints from the first file.
my $hp;
if ($tree->{"\\"}->{"Cmpnd"}->{"Root"}->{"File name"}) { #This is true for .cmp file names
	my $rootobj = clearstring($tree->{"\\"}->{"Cmpnd"}->{"Root"}->{"File name"});
	die "Can't find RootObject Name in $file\n" unless $tree->{"\\"}->{$rootobj};
	#print "Found Root in $file: $rootobj\n" #Uncomment this to check if the script finds it right..

	$hp = $tree->{"\\"}->{$rootobj}->{Hardpoints}; #Extract the whole hardpoint hash from the root object.
	# The file may contain more objects than "Root", I don't copy those hardpoint, because: If the ship looses that object the hardpoints are lost.
	# Those hardpoints are therefore useless.
}
else { #Must be .3db file then.
	$hp = $tree->{"\\"}->{Hardpoints} if $tree->{"\\"}->{Hardpoints};
}
die "Can't find Hardpoint in the Tree, please select a vailid cmp or 3db for $file\n" unless $hp;

foreach my $f (@ARGV) { #All targets:
	open FH, $f or die "Can't open target $f: $!\n";
	binmode FH;
	my $ntree=UTFread(do {local $/;<FH>});
	close FH;

	if ($ntree->{"\\"}->{"Cmpnd"}->{"Root"}->{"File name"}) {
		my $nrootobj = clearstring($ntree->{"\\"}->{"Cmpnd"}->{"Root"}->{"File name"});
		print "Skippded $file, no root\n" and next unless $ntree->{"\\"}->{$nrootobj};
		$ntree->{"\\"}->{$nrootobj}->{Hardpoints} = $hp; #Write hardpoints.
	}
	else {
		$ntree->{"\\"}->{Hardpoints} = $hp;
	}
	rename $f,"$f.bak";
	open FH, ">$f";
	binmode FH;
	print FH UTFwriteUTF($ntree); #Write the file again.
	close FH;
}
