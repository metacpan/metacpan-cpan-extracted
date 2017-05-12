#!/usr/bin/perl -w
# 
######################################################################
# 
# Example Application for image::ParseGIF - Status
#  (c) 1999 University of NSW
# 
# Written by Benjamin Low <ben@snrc.uow.edu.au>
#
#
######################################################################
#

use CGI_Lite;
use URI::Escape;
use Fcntl qw(:DEFAULT :flock);  # sysopen, flock symbolic constants

use Image::ParseGIF 0.10;

# open and parse the status GIF
my $image = new Image::ParseGIF ('progressbar.gif') or 
	die "could not parse GIF: $@\n";

# get the CGI request
my $CGI = new CGI_Lite;
my $query = $CGI->parse_form_data();

# get the request identifier
my $key = URI::Escape::uri_unescape($query->{'key'} || '');


# send back an image, frame at a time

$| = 1;
# 'no-cache' is probably not neccessary, but shouldn't hurt
print join("\n", (
	"Expires: 0",
	"Pragma: no-cache", 
	"Cache-Control: no-cache",
	"Content-type: image/gif", 
	"\n"));


# make sure key is valid - if we get called after the main 
#  server has been and gone
if (-s "/tmp/status.$key")
{
	# open the pipe
	open (STATUS, "/tmp/status.$key");

	$image->print_header;

	while (<STATUS>)
	{
		chomp($_);
		$image->print_percent($_);
	}

	$image->print_percent(1);	# complete the animation, just in case

	$image->print_trailer;
}

exit(0);

