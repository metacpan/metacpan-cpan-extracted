#!/usr/bin/perl

use warnings;
use strict;
use Games::Freelancer::UTF;

sub clearstring { #Clean up string in the tree, because value might have \0 in them sometimes, while keys don't.
	my $str=shift;
	return substr($str,0,index($str,"\0"));
}

unless (@ARGV) {
	print "Extracts all Images from cmp, vms, 3db or mat files\nUsage: $0 file [file ...]\n";
	exit;
}

foreach my $file (@ARGV) {
	open FH, $file or die "Can't open $file: $!";
	binmode FH;
	my $tree=UTFread(do {local $/;<FH>}); #Read the file with UTFread()
	close FH;
	my $textlib;
	if ($tree->{"\\"}->{"Cmpnd"}->{"Root"}->{"File name"}) { #Try to find the root object first, maybe it has a library (mostly it doesn't)
		my $rootobj = clearstring($tree->{"\\"}->{"Cmpnd"}->{"Root"}->{"File name"});
		$textlib = $tree->{"\\"}->{$rootobj}->{"Texture library"} if $tree->{"\\"}->{$rootobj} and $tree->{"\\"}->{$rootobj}->{"Texture library"};
		$textlib = $tree->{"\\"}->{$rootobj}->{"texture library"} if $tree->{"\\"}->{$rootobj} and $tree->{"\\"}->{$rootobj}->{"texture library"};
	}
	if (not $textlib) {#Try the 'normal' places.
		$textlib = $tree->{"\\"}->{"Texture library"} if $tree->{"\\"}->{"Texture library"};
		$textlib = $tree->{"\\"}->{"texture library"} if $tree->{"\\"}->{"texture library"};
	}
	warn "Can't find Texture Library in the Tree of $file, please select a vailid cmp or 3db for $file\n" and next unless $textlib;
	foreach my $k (keys %{$textlib}) {
		foreach my $f (keys %{$textlib->{$k}}) {
			print "$file.$f.$k\n"; #Write it into some file
			open FH,">$file.$f.$k" or (warn "Can't open output $file.$f.$k" and next);
			binmode FH;
			print FH $textlib->{$k}->{$f};
			close FH;
		}
	}
}
