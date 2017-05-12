#!/usr/bin/perl -w

# author : sergey s prozhogin (ccpro@rrelaxo.org.ru)
# script renames file by EXIF date
# for information start perl rename.pl
#
# v 1.3 May-20-2004
#

use strict;
use Image::EXIF;
use Date::Parse;
use Data::Dumper;

my @list = `ls -1 *JPG *jpg *jpeg *JPEG`;

my $exif = new Image::EXIF;

for my $fname (@list)
{
	chomp $fname;

	$exif->file_name($fname);
	my $data = $exif->get_all_info();

	if ($data)
	{
		my $timestamp = $data->{image}->{'Image Created'} || $data->{other}->{'Image Generated'};
		my $time = str2time($timestamp);

		$timestamp = sprintf "%x", $time;

		my $count = 0;
		while (-f "img_$timestamp$count.jpg")
		{
			$count ++;
		}

		rename $fname, "img_$timestamp$count.jpg";
	}
}
