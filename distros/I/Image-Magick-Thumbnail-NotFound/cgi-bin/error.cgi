#!/usr/bin/perl -w
use strict;
use Image::Magick::Thumbnail::NotFound; 

# Will exit on succeed.
new Image::Magick::Thumbnail::NotFound;

# use this constructor instead for 125px square thumbs
#new Image::Magick::Thumbnail::NotFound ({ square => 1, restriction => 125, });


# if no thumbnail was asked for or there were errors...
print "Content-type: text/html\n\n";
print 'Sorry, '.$ENV{REQUEST_URI}.' is unavailable.';
exit;
