###########################################################
# A Perl package for showing/modifying JPEG (meta)data.   #
# Copyright (C) 2004,2005,2006 Stefano Bettelli           #
# See the COPYING and LICENSE files for license terms.    #
###########################################################
use Image::MetaData::JPEG::data::Tables qw(:TagsAPP14);
no  integer;
use strict;
use warnings;

###########################################################
# This method parses a misterious Adobe APP14 segment.    #
# Adobe uses this segment to record information at the    #
# time of compression such as whether or not the sample   #
# values were blended and which color transform was       #
# performed upon the data. The format is the following:   #
#---------------------------------------------------------#
#  5 bytes  "Adobe" as identifier (non null-terminated)   #
#  2 bytes  DCTEncode/DCTDecode version number (0x65)     #
#  2 bytes  flags0                                        #
#  2 bytes  flags1                                        #
#  1 byte   transform code                                #
#=========================================================#
# Ref: "Supporting the DCT Filters in PostScript Level 2",#
#      Adobe Developer Support, Tech. note #5116, pag.27  #
###########################################################
sub parse_app14 {
    my ($this) = @_;
    my $offset = 0;
    # exactly 12 bytes, or die
    $this->test_size(12);
    # they say that this segment always starts with a specific
    # string from Adobe, namely "Adobe". For the time being,
    # die if you find something else
    my $identifier = $this->store_record
	('Identifier', $ASCII, $offset, 5)->get_value();
    $this->die("Wrong identifier ($identifier)")
	if $identifier ne $APP14_PHOTOSHOP_IDENTIFIER;
    # the rest is trivial
    $this->store_record('DCT_TransfVersion' , $SHORT, $offset   );
    $this->store_record('Flags0'            , $UNDEF, $offset, 2);
    $this->store_record('Flags1'            , $UNDEF, $offset, 2);
    $this->store_record('TransformationCode', $BYTE,  $offset   );
}

# successful load
1;
