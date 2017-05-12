#!/usr/bin/perl -w
# -*- perl -*-

#
# $Id: 30newfrom.t,v 1.8 2008/11/22 08:17:51 eserte Exp $
# Author: Slaven Rezic
#

use strict;
use FindBin;

use GD;

$GD::Convert::DEBUG = 0;

BEGIN {
    if (!eval q{
	use Test::More;
	use File::Temp qw(tempfile);
	GD::Image->can("compare") or die;
	1;
    }) {
	print "1..0 # skip: no Test::More and/or File::Temp modules or GD::Image does not support compare\n";
	exit;
    }

    if (!eval q{
	use GD::Convert qw(gif=any newFromGif=any newFromGifData=any);
	1;
    }) {
	if ($@ =~ /Can't find any converter for (?:gif|newFromGif)/) {
	    print "1..0 # skip: no gif converter available on this system\n";
	    exit;
	}
	die $@;
    }
}

plan tests => 8;

diag "";
while(my($k,$v) = each %GD::Convert::installed) {
    diag "$k -> $v";
}

my $gd = GD::Image->new(100,100);
my $black = $gd->colorAllocate(0,0,0);
my $red   = $gd->colorAllocate(255,0,0);
$gd->line(0,0,100,100,$red);

######################################################################
# PPM tests

my $ppm_data = $gd->ppm;

{
    my $gd2 = GD::Image->newFromPpmData($ppm_data);
    is($gd->compare($gd2) & &GD::GD_CMP_IMAGE, 0, "PPM output and input (data)");
}

my(undef, $ppm_file) = tempfile(UNLINK => 1, SUFFIX => ".ppm");
die "Cannot create temporary file: $!" if !$ppm_file;

open(OUT, ">$ppm_file") or die "Can't write $ppm_file: $!";
binmode OUT;
print OUT $ppm_data;
close OUT;

{
    my $gd2 = GD::Image->newFromPpm($ppm_file);
    is($gd->compare($gd2) & &GD::GD_CMP_IMAGE, 0, "PPM input (file)");
}

{
    open(IN, $ppm_file) or die "Can't read $ppm_file: $!";
    binmode IN;
    my $gd2 = GD::Image->newFromPpm(\*IN);
    close IN;
    is($gd->compare($gd2) & &GD::GD_CMP_IMAGE, 0, "PPM input (filehandle)");
}

{
    require IO::File;
    my $fh = IO::File->new;
    $fh->open("< $ppm_file") or die "Can't read $ppm_file: $!";
    # $fh->binmode; XXX?
    my $gd2 = GD::Image->newFromPpm($fh);
    $fh->close;
    is($gd->compare($gd2) & &GD::GD_CMP_IMAGE, 0, "PPM input (IO::File)");
}

unlink $ppm_file;

######################################################################
# GIF tests

my $gif_data = $gd->gif;

my $gd3 = GD::Image->newFromGifData($gif_data);
is($gd->compare($gd3) & &GD::GD_CMP_IMAGE, 0, "GIF output and input (data)");

my(undef, $gif_file) = tempfile(UNLINK => 1, SUFFIX => ".gif");
die "Cannot create temporary file: $!" if !$ppm_file;

open(OUT, ">$gif_file") or die "Can't write $gif_file: $!";
binmode OUT;
print OUT $gif_data;
close OUT;

{
    my $gd2 = GD::Image->newFromGif($gif_file);
    is($gd->compare($gd2) & &GD::GD_CMP_IMAGE, 0, "GIF input (file)");
}

{
    open(IN, $gif_file) or die "Can't read $gif_file: $!";
    binmode IN;
    my $gd2 = GD::Image->newFromGif(\*IN);
    close IN;
    is($gd->compare($gd2) & &GD::GD_CMP_IMAGE, 0, "GIF input (filehandle)");
}

{
    require IO::File;
    my $fh = IO::File->new;
    $fh->open("< $gif_file") or die "Can't read $gif_file: $!";
    # $fh->binmode; XXX?
    my $gd2 = GD::Image->newFromGif($fh);
    $fh->close;
    is($gd->compare($gd2) & &GD::GD_CMP_IMAGE, 0, "GIF input (IO::File)");
}

unlink $gif_file;

__END__
