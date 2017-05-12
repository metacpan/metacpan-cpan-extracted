#!/usr/bin/perl
use strict;
use warnings;

use lib "lib";

use Image::Hash;
use File::Slurp;
use Getopt::Std;

my %opts;
getopts('l:', \%opts);

my @modules;
if ($opts{'l'}) {
	@modules = split(/,/, $opts{'l'});
}
else {
	@modules =  qw( GD ImageMagick Imager );
}

if ($#ARGV < 0) {
	die("Pleas spesyfi at least one file to read!");
}

while (my $file = shift @ARGV) {

	print "\n\n$file:\n";


	my $image = read_file( $file, binmode => ':raw' ) ;


	print "ahash:\n";
	for my $module ( @modules ) {
		my $ihash = Image::Hash->new($image, $module);
		printf("%-15s: %-16s %s\n", $module, scalar $ihash->ahash(), join('', $ihash->ahash()));
	}

	print "\ndhash:\n";
	for my $module ( @modules ) {
		my $ihash = Image::Hash->new($image, $module);
		printf("%-15s: %-16s %s\n", $module, scalar $ihash->dhash(), join('', $ihash->dhash()));
	}

	print "\nphash:\n";
	for my $module ( @modules ) {
		my $ihash = Image::Hash->new($image, $module);
		printf("%-15s: %-16s %s\n", $module, scalar $ihash->phash(), join('', $ihash->phash()));
	}


	print "\ngreytones:\n";
	for my $module ( @modules ) {
		my $ihash = Image::Hash->new($image, $module);
		printf("%-15s: %s\n", $module, $ihash->greytones() );
	}


	print "\ndump with aHash highlighted:\n";
	for my $module ( @modules ) {
		my $ihash = Image::Hash->new($image, $module);

		print "$module:\n";
		my @hash = $ihash->ahash();
		$ihash->dump('hash' => \@hash );
		print "\n";
	}

}
