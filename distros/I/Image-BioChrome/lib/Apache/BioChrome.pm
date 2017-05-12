#
# Apache::BioChrome
#
# An apache handler designed to call the Image::BioChrome engine to recolor
# images at the point they are requested from the web server
#
# Author: Simon Matthews <sam@tt2.org>
#
# Copyright (C) 2003 Simon Matthews.  All Rights Reserved.
#
# This module is free software; you can distribute it and/or modify is under
# the same terms as Perl itself.
#

package Apache::BioChrome;

use strict;

# get the DECLINED and OK constants
use Apache::Constants qw(REDIRECT DECLINED OK);

# required for mkpath
use File::Path;
# use File::Copy;
use File::Temp qw/ tempfile /;

# use the BioChrome module to do the image colorising
use Image::BioChrome;

use vars qw($VERSION $DEBUG $MOD);

$VERSION = sprintf("%d.%02d", q$Revision: 1.4 $ =~ /(\d+)\.(\d+)/);

$MOD = 'Apache::BioChrome';

$DEBUG = 0;

sub handler {
	my ($r) = @_;

	return DECLINED unless $r->is_main();

	# get the filename that has been mapped for this file
	my $fn = $r->filename();

	# if we have a file name then something has already translated the 
	# request which if they returned ok should mean that we don't get 
	# called.  However it would appear that mod_perl calls all the 
	# handlers irrespective of their return status

	# if the filename is set then return OK
	return OK if $fn;

	my $color = '';
	my $mode = '';
	my $src_file = '';

	print STDERR "$MOD: handler called\n" if $DEBUG;

	# if there is no config then decline to process the request
	my $out = $r->dir_config("biochrome_cache") || return DECLINED;

	# we must either have a source directory or a path defained
	my $src  = $r->dir_config('biochrome_source') || '';
	my $path = $r->pnotes('biochrome_path') ||
			   $r->dir_config('biochrome_path') || '';

	return DECLINED unless $src || $path;

	print STDERR "$MOD: called translating.....\n" if $DEBUG;

	# get a copy of the URI
	my $uri = $r->uri() || '';

	# get the location that we are in
	my $loc = $r->location();

	# sometimes we seem to get a blank uri which is a very strange request 
	# indeed but we definately don't want to handle it so return declined
	return DECLINED unless $uri;

	# dump some useful info
	if ($DEBUG) {
		print STDERR "$MOD: Trans URI = [$uri]\n";
		print STDERR "$MOD: Location = [$loc]\n";
		print STDERR "$MOD: Filename = [$fn]\n";
		print STDERR "$MOD: Cache Directory =  [$out]\n";
		print STDERR "$MOD: Source Directory =  [$src]\n";
	}

	# take a copy of the uri to use in the mapping of the file names
	my $cf = $uri;

	# remove the location from the file name 
	$cf =~ s/^${loc}//;

	print STDERR "$MOD: Look for file [$cf]\n" if $DEBUG;

	# we will cache the files using the full uri so that we don't get 
	# clashes when the same image exists under different urls
	my $dst_file = $out . $uri;

	# grab the mode and the color from the start of the file
	if ($cf =~ m:/?(alpha)?(([_]?[0-9a-f]{6})+)?(/.*$):) {
		print STDERR "$MOD: Matched some colors [$2] for file [$4]\n" if $DEBUG;
		$mode = $1 || '';
		$color = $2 || '';
		$src_file = $4;
	}

	return DECLINED unless $src_file;

	if ($path) {
		# chech each directory on the path for the file
		$src_file = check_path($path, $src_file);
		return DECLINED unless $src_file;
	} else {
		$src_file = $src . $src_file;
	}

	print STDERR "$MOD: mode [$mode]\n" if $DEBUG;
	print STDERR "$MOD: src file [$src_file] -> [$dst_file]\n" if $DEBUG;

	# check if the file is in the cache already
	if (1 && -f $dst_file && -f $src_file) {
		if ((stat($src_file))[9] < (stat($dst_file))[9]) {
			print STDERR "$MOD: [$dst_file] in cache\n" 
				if $DEBUG;
			$r->filename($dst_file);
			return OK;
		} else {
			print STDERR "$MOD: rebuild file\n" 
				if $DEBUG;
		}
	}

	my $full = $dst_file;
	$full =~ s/\/[^\/]+$//;

	print STDERR "$MOD: Full Directory =  [$full]\n" if $DEBUG;

	# ensure that we have the directory that we need to put the files in
	unless (-d $full) {
		eval { mkpath($full) };
		if ($@) {
			print STDERR "$MOD: Failed to create directory [$full]\n" if $DEBUG;
			return DECLINED;
		}

		print STDERR "$MOD: Created Full Directory =  [$full]\n" if $DEBUG;
	}

	if (-f $src_file) {

		print STDERR "$MOD: source file exists [$src_file]\n" if $DEBUG;
		my $bio = new Image::BioChrome $src_file;

		print STDERR "$MOD: biochrome created for [$src_file]\n" if $bio 
			&& $DEBUG;

		# if we were not able to create the BioChrome object
		return DECLINED unless $bio;

		# pass the color information to the BioChrome object
		if ($mode eq 'alpha') {
			$bio->alphas($color) if $color;
		} else {
			$bio->colors($color) if $color;
		}

		$bio->write_file( $dst_file );

		$r->filename($dst_file);
		return OK;
	}

	print STDERR "$MOD: Chameleon: SAM stops here\n" if $DEBUG;
	return DECLINED;

}


sub check_path {
	my $path = shift;
	my $file = shift;

	foreach my $dir (split(/[:;]/, $path)) {

		print STDERR "Check path checks file [$dir$file]\n" if $DEBUG;
		if (-f $dir . $file ) {
			return $dir . $file;
		}
	}

	return;
}

1;

=head1 NAME

Apache::BioChrome - Apache handler for Image::BioChrome to colorise gif files based on information provided in the url

=head1 SYNOPSIS

    #httpd.conf
    PerlTransHandler Apache::BioChrome

    # anywhere you can configure a location
    <Location /biochrome>
        PerlSetVar biochrome_cache /tmp/biochrome
        PerlSetVar biochrome_source /usr/www/images/biochrome
    </Location>

=head1 DESCRIPTION

This module is designed to allow the automatic building of gif images that 
make up an interface by using the Image::BioChrome module to replace values 
in the global color table.  It takes the color information from the URL and 
creates a copy of the gif file from the source directory in the location 
specified by the biochrome cache variable.  This file is then returned by 
apache using the standard delivery method.

I developed this module because we produce lots of web sites where a high
proportion of the site interface is common.  But where images need to be in
a different color for specific sites.

Once you have the handler setup as above you can call it in two different ways:

/biochrome/alpha_ff0000_0000ff/picure.gif

Will take the file picture.gif and do an alpha map replacement using the colors
ff0000 and 0000ff as the two ends of the spectrum.  The use of alpha maps should
be familiar to anyone who uses photoshop or gimp a lot.  Essentially the colors 
are taken from the url and used as follows.  The first color will be the
background color of the image.  The second color will be applied to those pixels
where the red channel is turned on.

/biochrome/ff0000_00ff00_0000ff_ccffff/picure.gif

Will take the file and replace colors in the global color table with those 
provided on the url.  In the example whatever color was the first in the color
table will be replaced with red.  Colors are replaced until we run out of 
replacements or positions in the color table to replace.

For further details of how to create your graphics and examples of using 
BioChrome see the examples directory or the Image::BioChrome documentation.

=head1 AUTHOR

Simon Matthews E<lt>sam@tt2.orgE<gt>

=head1 REVISION

$Revision: 1.4 $

=head1 COPYRIGHT 

Copyright (C) 2003 Simon Matthews.  All Rights Reserved.

This module is free software; you can distribute it and/or modify 
it under the same terms as Perl itself.

=head1 SEE ALSO

See L<Image::BioChrome> for further information on using BioChrome.

=cut
