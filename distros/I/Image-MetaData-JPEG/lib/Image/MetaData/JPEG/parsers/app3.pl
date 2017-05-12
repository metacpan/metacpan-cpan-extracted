###########################################################
# A Perl package for showing/modifying JPEG (meta)data.   #
# Copyright (C) 2004,2005,2006 Stefano Bettelli           #
# See the COPYING and LICENSE files for license terms.    #
###########################################################
use Image::MetaData::JPEG::data::Tables qw(:TagsAPP3);
no  integer;
use strict;
use warnings;

###########################################################
# This method parses an APP3 Exif segment, which is very  #
# similar to an APP1 Exif segment (infact, it is its      #
# extension with additional tags, see parse_app1_exif for #
# additional details). The structure is as follows:       #
#---------------------------------------------------------#
#  6 bytes  identifier ('Meta\000\000' = 0x4d6574610000)  #
#  2 bytes  TIFF header endianness ('II' or 'MM')         #
#  2 bytes  TIFF header signature (a fixed value = 42)    #
#  4 bytes  TIFF header: offset of 0th IFD                #
# ...IFD... 0th IFD (mandatory, I think)                  #
# ...IFD... Special effects IFD (optional) linked by IFD0 #
# ...IFD... Borders IFD (optional) linked by IFD0         #
#=========================================================#
# Ref: ... ???                                            #
###########################################################
sub parse_app3 {
    my ($this) = @_;
    # decode and save the identifier (it should be 'Meta\000\000'
    # for an APP3 segment) and die if it is not correct.
    my $identifier = $this->store_record
	('Identifier', $ASCII, 0, length $APP3_EXIF_TAG)->get_value();
    $this->die("Incorrect identifier ($identifier)")
	if $identifier ne $APP3_EXIF_TAG;
    # decode the TIFF header (records added automatically in root);
    # it should be located immediately after the identifier
    my ($tiff_base, $ifd0_link, $endianness) = 
	$this->parse_TIFF_header(length $identifier);
    # Remember to convert the ifd0 offset with the TIFF header base.
    my $ifd0_offset = $tiff_base + $ifd0_link;
    # locally set the current endianness to what we have found.
    local $this->{endianness} = $endianness;
    # parse all the records of the 0th IFD, as well as their subdirs
    $this->parse_ifd('IFD0', $ifd0_offset, $tiff_base, 1);
}

# successful load
1;
