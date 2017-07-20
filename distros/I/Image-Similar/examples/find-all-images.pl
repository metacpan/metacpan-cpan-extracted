#!/home/ben/software/install/bin/perl

# Construct a list of all images on the accessible file systems.

use warnings;
use strict;
use File::Find;
use FindBin '$Bin';

# The list of files under construction.

my @files;
main ();
exit;

# This returns a true value if its argument is an image file.

sub is_image_file
{
    my ($file) = @_;
    if ($file =~ /\.(jpg|png|gif|jpeg)$/i) {
	return 1;
    }
    return undef;
}

sub check_file
{
    if (is_image_file ($File::Find::name)) {
	push @files, $File::Find::name;
    }
}

sub write_files
{
    open my $out, ">", "$Bin/image-list.txt" or die $!;
    for (@files) {
	print $out "$_\n";
    }
    close $out or die $!;
}

sub main
{
    find ({
	wanted => \& check_file,
    }, "$Bin/..");
    write_files ();
}
