#!/usr/bin/perl
use warnings;
use strict;

my $BASENAME;

BEGIN {
	$BASENAME = ($0 =~ m|(.*)/(.+)|) ? ($1?$1:'/') : '.';
	push(@INC,"$BASENAME/../lib");
}

use Test::More;

# Make sure we can include the module

use_ok('Image::BMP');

#use Image::BMP;

my @files = @ARGV ? @ARGV : glob("$BASENAME/images/*.bmp");

sub getImg {
	my ($f) = @_;
	my $img;
	#$f="convert $f bmp:- |" unless $f =~ /\.bmp$/;
	$img = Image::BMP->new(file => $f, ignore_imagemagick_bug => 1);
	$img->debug(2);
	$img;
}

sub diff {
	my ($a,$b) = @_;
	
	open(my $afh, '<', $a) || return print STDERR "Couldn't open file $a for diff\n";
	open(my $bfh, '<', $b) || return print STDERR "Couldn't open file $b for diff\n";

	my $diffs = 0;
	while (!eof($afh) && !eof($bfh)) {
		my $linea = scalar <$afh>;
		my $lineb = scalar <$bfh>;
		next if $linea eq $lineb;
		$diffs += 1;
		print "< $linea";
		print "> $lineb";
	}

	return $diffs unless $diffs==0;
	return print STDERR "diff file $b finished before $a\n" if eof($afh) && !eof($bfh);
	return print STDERR "diff file $a finished before $b\n" if !eof($afh) && eof($bfh);

	close($afh);
	close($bfh);
	return 0;
}

sub testImg {
	my ($f) = @_;
	my $expect = $f; $expect =~ s/(\.[^\.]{1,3})?$/.expect/;
	my $out = $f; $out =~ s/(\.[^\.]{1,3})?$/.txt/;
	unless (-f $expect) {
		print "Skipping: $f [No .expect]\n";
		return unless -f $expect;
	}
	#print "TEST: $f\n";

	my $img = getImg($f);
	$img->view_ascii($out);
	ok(!diff($out, $expect), "image check: $f");
	unlink($out);
}

foreach my $file ( @files ) {
	testImg($file);
}


done_testing();

1;
