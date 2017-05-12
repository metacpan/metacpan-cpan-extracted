###########################################################
# A Perl package for showing/modifying JPEG (meta)data.   #
# Copyright (C) 2004,2005,2006 Stefano Bettelli           #
# See the COPYING and LICENSE files for license terms.    #
###########################################################
use Image::MetaData::JPEG::data::Tables qw(:TagsAPP1_Exif :TagsAPP1_XMP);
no  integer;
use strict;
use warnings;

###########################################################
# This method parses an APP1 segment. Such an application #
# segment can host a great deal of metadata, in at least  #
# two formats (see specialised routines for more details):#
#   1) Exif JPEG files use APP1 so that they do not con-  #
#      flict with JFIF metadata (which use APP0);         #
#   2) Adobe, in order to be more standard compliant than #
#      others, uses APP1 for its XMP metadata format.     #
# This method decides among the various formats and then  #
# calls a more specialised method. An error is issued if  #
# the metadata format is not recognised.                  #
#=========================================================#
# Ref: "Exchangeable image file format for digital still  #
#      cameras: Exif Version 2.2", JEITA CP-3451, Apr2002 #
#    Japan Electronic Industry Development Assoc. (JEIDA) #
# and: "XMP Specification", version 3.2, June 2005, Adobe #
#      Systems Inc., San Jose, CA, http://www.adobe.com   #
###########################################################
sub parse_app1 {
    my ($this) = @_;
    # If the data area begins with "Exif\000\000" it is an Exif section
    return $this->parse_app1_exif()
	if $this->data(0, length $APP1_EXIF_TAG) eq $APP1_EXIF_TAG;
    # If it begins with "http://ns.adobe.com/xap/1.0/", it is Adobe XMP
    return $this->parse_app1_xmp()
	if $this->data(0, length $APP1_XMP_TAG) eq $APP1_XMP_TAG;
    # if the segment type is unknown, generate an error
    $this->die('Incorrect identifier (' . $this->data(0,6) . ')');
}

require 'Image/MetaData/JPEG/parsers/app1_exif.pl';
require 'Image/MetaData/JPEG/parsers/app1_xmp.pl';

# successful load
1;
