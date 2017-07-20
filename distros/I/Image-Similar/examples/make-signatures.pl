#!/home/ben/software/install/bin/perl

# Make signatures for all the images.

use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Image::Similar ':all';
use Imager;

main ();

sub main
{
    my %sigs;
    open my $in, "<", "$Bin/image-list.txt" or die $!;
    while (<$in>) {
	chomp;
	if (/^\s*$/) {
	    next;
	}
	my $image = $_; 
	my $imager = Imager->new ();
	my $ok = $imager->read (file => $image); 
	if (! $ok) {
	    warn "$image is not ok: ", $imager->errstr ();
	    next;
	}
	my $is = load_image ($imager);
	my $sig = $is->signature ();
	if (! $sig) {
	    die "No signature for $image";
	}
	if ($sigs{$sig}) {
	    # Identical match.
	    print "$sigs{$sig} looks identical to $image.\n";
	}
	else {
	    for my $k (keys %sigs) {
		my $diff = $is->sig_diff ($k);
		if ($diff < 0.1) {
		    print "$sigs{$k} looks similar to $image.\n";
		}
	    }
	    # Don't overwrite $sigs{$sig} if it already has a value.
	    $sigs{$sig} = $image;
	}
    }
    close $in or die $!;
}
