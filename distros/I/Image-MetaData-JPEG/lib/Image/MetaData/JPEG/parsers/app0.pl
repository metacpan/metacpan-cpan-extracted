###########################################################
# A Perl package for showing/modifying JPEG (meta)data.   #
# Copyright (C) 2004,2005,2006 Stefano Bettelli           #
# See the COPYING and LICENSE files for license terms.    #
###########################################################
use Image::MetaData::JPEG::data::Tables qw(:TagsAPP0);
no  integer;
use strict;
use warnings;

###########################################################
# This method parses an APP0 segment. APP0 segments are   #
# written by older cameras adopting the JFIF (JPEG File   #
# Interchange Format) for storing images. JFIF uses the   #
# APP0 application segment for inserting configuration    #
# data and a thumbnail image. The format is as follows:   #
#---------------------------------------------------------#
#  5 bytes  identifier ('JFIF\000' = 0x4a46494600)        #
#  1 byte   major version (e.g. 0x01)                     #
#  1 byte   minor version (e.g. 0x01 or 0x02)             #
#  1 byte   units (0: densities give aspect ratio         #
#                  1: density values are dots per inch    #
#                  2: density values are dots per cm)     #
#  2 bytes  Xdensity (Horizontal pixel density)           #
#  2 bytes  Ydensity (Vertical pixel density)             #
#  1 byte   Xthumbnail (Thumbnail horizontal pixel count) #
#  1 byte   Ythumbnail (Thumbnail vertical pixel count)   #
# 3n bytes  (RGB)n, packed (24-bit) RGB values for the    #
#           thumbnail pixels, n = Xthumbnail * Ythumbnail #
#---------------------------------------------------------#
# There is also an "extended" version of JFIF (only pos-  #
# sible for JFIF versions 1.02 and above). In this case   #
# the identifier is not 'JFIF' but 'JFXX'. The syntax in  #
# this case is modified as follows:                       #
#---------------------------------------------------------#
#  5 bytes  identifier ('JFXX\000' = 0x4a46585800)        #
#  1 byte   extension  (0x10 Thumbnail coded using JPEG   #
#                       0x11 Thumbnail using 1 byte/pixel #
#                       0x13 Thumbnail using 3 bytes/pixel#
#---------------------------------------------------------#
# The remainder of the segment varies with the extension. #
#---------------------------------------------------------#
# Thumbnail coded using JPEG: the compressed thumbnail    #
# immediately follows the extension code in the extension #
# data field and the length must be included in the JFIF  #
# extension APP0 marker length field. The extension data  #
# field conforms to the syntax for a JPEG file (SOI ....  #
# SOF ... EOI); however, no 'JFIF' or 'JFXX' marker seg-  #
# ments shall be present.                                 #
#---------------------------------------------------------#
# Thumbnail stored using one byte per pixel: this must    #
# include a thumbnail and a colour palette as follows:    #
#  1 byte   Xthumbnail (Thumbnail horizontal pixel count) #
#  1 byte   Ythumbnail (Thumbnail vertical pixel count)   #
# 768 bytes palette (24-bit RGB pixel values for the      #
#                    colour palette. These values define  #
#                    the colors represented by each value #
#                    of an 8-bit binary encoding (0-255)) #
# n bytes   pixels  (8-bit values for the thumbnail       #
#                    pixels: n = Xthumbnail * Ythumbnail) #
#---------------------------------------------------------#
# Thumbnail stored using three bytes per pixel: in this   #
# case there is no colour palette:                        #
#  1 byte   Xthumbnail (Thumbnail horizontal pixel count) #
#  1 byte   Ythumbnail (Thumbnail vertical pixel count)   #
# 3n bytes  pixels (24-bit RGB values for the thumbnail   #
#                   pixels, n = Xthumbnail * Ythumbnail)  #
#---------------------------------------------------------#
# Ref: http://www.dcs.ed.ac.uk/home/mxr/gfx/2d/JPEG.txt   #
###########################################################
sub parse_app0 {
    my ($this) = @_;
    my $offset = 0;
    my $thumb_x_dim = 0; my $thumb_y_dim = 0;

    # Decode the APP0 app-extension identifier. It's an arbitrarily
    # long string, terminated by binary zero. Find length:
    my $length = 1; # assuming the app id is at least one byte long should be safe
    for(;;){
	my $byte = $this->data($length, 1);
	last if $byte eq "\x00";
	last if $length >= $this->size(); # no infinite loop
	$length++;
    }
    my $identifier = $this->store_record
	('Identifier', $ASCII, $offset, $length + 1)->get_value(); # +1 as Tables.pm currently includes the null-terminator
    # go to the appropriate decoding routine depending on found identifier
    goto APP0_simple   if $identifier eq $APP0_JFIF_TAG;
    goto APP0_extended if $identifier eq $APP0_JFXX_TAG;
    # JPEG specs tell us to simply ignore unknown identifiers
    # $this->die("Unknown identifier ($identifier)");
    $offset += ($this->size() - $length - 1); # skip over (NOPARSE) unknown data
    goto APP0_END;
  APP0_simple:
    # as far as I know, in a JFIF APP0 there are always the following
    # seven fields, even if the thumbnail is absent. This means that
    # at least 14 bytes (including the initial identifier) must be there.
    # Do a test size and then read the fields.
    $this->test_size($offset + 9);
    $this->store_record('MajorVersion', $BYTE , $offset);
    $this->store_record('MinorVersion', $BYTE , $offset);
    $this->store_record('Units'       , $BYTE , $offset);
    $this->store_record('XDensity'    , $SHORT, $offset);
    $this->store_record('YDensity'    , $SHORT, $offset);
    $thumb_x_dim =$this->store_record('XThumbnail',$BYTE,$offset)->get_value();
    $thumb_y_dim =$this->store_record('YThumbnail',$BYTE,$offset)->get_value();
    # now calculate the size of the thumbnail data area. This
    # is three times the product of the two previous dimensions.
    my $thumb_size = 3 * $thumb_x_dim * $thumb_y_dim;
    # issue an error if the thumbnail data area is not there
    $this->test_size($offset + $thumb_size, "corrupted thumbnail");
    # if size is positive, get the packed thumbnail as unknown
    $this->store_record('ThumbnailData', $UNDEF, $offset, $thumb_size) 
	if $thumb_size > 0;
    goto APP0_END;
  APP0_extended:
    # so this is an extended JFIF (JFXX). Get the extension code
    my $ext_code = $this->store_record
	('ExtensionCode', $BYTE, $offset)->get_value();
    # now, depending on it, go to another parsing segment
    goto APP0_ext_jpeg   if  $ext_code == $APP0_JFXX_JPG;
    goto APP0_ext_bytes  if ($ext_code == $APP0_JFXX_1B ||
			     $ext_code == $APP0_JFXX_3B);
    # if we are still here, die of unknown extension code
    $this->die("Unknown extension code ($ext_code)");
  APP0_ext_jpeg:
    # in this case, the rest of the data area is a jpeg image
    # which we save as undefined data in a single field. We don't
    # dare to check the syntax of these data and go to the end.
    $this->store_record('JPEGThumbnail',$UNDEF,$offset,$this->size()-$offset);
    goto APP0_END;
  APP0_ext_bytes:
    # for the other two extensions, we first make sure that there
    # are two other bytes, then we read the thumbnail size
    $this->test_size($offset + 2, "no thumbnail dimensions");
    $thumb_x_dim =$this->store_record('XThumbnail',$BYTE,$offset)->get_value();
    $thumb_y_dim =$this->store_record('YThumbnail',$BYTE,$offset)->get_value();
    # now calculate the number of pixels in the thumbnail data area.
    # This is the product of the two previous dimensions.
    my $thumb_pixels = $thumb_x_dim * $thumb_y_dim;
    # now, the two extensions take different routes ...
    goto APP0_ext_1byte  if $ext_code eq $APP0_JFXX_1B;
    goto APP0_ext_3bytes if $ext_code eq $APP0_JFXX_3B;
  APP0_ext_1byte:
    # in this case, there must be 768 bytes for the palette, followed
    # by $thumb_pixels for the thumbnail. Issue an error otherwise
    $this->test_size($offset + $APP0_JFXX_PAL + $thumb_pixels,
		     "Incorrect thumbnail data size in JFXX 0x10");
    # store the colour palette and the thumbnail as
    # undefined data and we have finished.
    $this->store_record('ColorPalette'  , $UNDEF, $offset, $APP0_JFXX_PAL);
    $this->store_record('1ByteThumbnail', $UNDEF, $offset, $thumb_pixels);
    goto APP0_END;
  APP0_ext_3bytes:
    # in this case, there must be 3 * $thumb_pixels
    # for the thumbnail data. Issue an error otherwise
    $this->test_size($offset + 3 * $thumb_pixels,
		     "Incorrect thumbnail data size in JFXX 0x13");
    # store the thumbnail as undefined data and we have finished.
    $this->store_record('3BytesThumbnail', $UNDEF, $offset, 3 * $thumb_pixels);
    goto APP0_END;
  APP0_END:
    # check that there are no spurious data in the segment
    $this->test_size(-$offset, "unknown data at segment end");
}

# successful load
1;
