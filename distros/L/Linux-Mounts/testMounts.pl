#!/usr/bin/perl -w 

use strict;
use Linux::Mounts;

my $mtd  = Linux::Mounts->new();
my $list = $mtd->list_mounts();

print "Number of mounted file systems : ", $mtd->num_mounts(), "\n\n";

print "List of mounted file systems :\n";
for ( my $i = 0; $i < $mtd->num_mounts(); $i++ ) {
	for ( my $j = 0; $j < $#{ $list }; $j++ ) {
		printf ("%-15s", $list->[$i][$j]);	
	}
	print "\n";
}

# or simplier ...

print "\nList of mounted file systems :\n";
$mtd->show_mount();

