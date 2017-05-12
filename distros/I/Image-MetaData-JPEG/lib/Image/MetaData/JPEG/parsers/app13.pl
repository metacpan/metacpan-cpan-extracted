###########################################################
# A Perl package for showing/modifying JPEG (meta)data.   #
# Copyright (C) 2004,2005,2006 Stefano Bettelli           #
# See the COPYING and LICENSE files for license terms.    #
###########################################################
use Image::MetaData::JPEG::data::Tables qw(:TagsAPP13);
no  integer;
use strict;
use warnings;

###########################################################
# This method parses an APP13 segment, often used by pho- #
# to-manipulation programs to store IPTC (International   #
# Press Telecommunications Council) tags, although this   #
# isn't a formally defined standard (first adopted by     #
# Adobe). The structure of an APP13 segment is as follows #
#---------------------------------------------------------#
# 14 bytes  identifier, e.g. "Photoshop 3.0\000"          #
#  8 bytes  resolution (?, Photoshop 2.5 only)            #
#   .....   sequence of Photoshop Image Resource blocks   #
#=========================================================#
# The sequence of resource blocks may require additional  #
# APP13 markers, whose order is always to be preserved.   #
# TODO: implement parsing of multiple blocks!!!!          #
#=========================================================#
# Ref: "Adobe Photoshop 6.0: File Formats Specifications",#
#      Adobe System Inc., ver.6.0, rel.2, November 2000.  #
# and  "\"Solo\" Image File Format. RichTIFF and its      #
#       replacement by \"Solo\" JFIF", version 2.0a,      #
#       Coatsworth Comm. Inc., Brampton, Ontario, Canada  #
###########################################################
sub parse_app13 {
    my ($this) = @_;
    my $offset = 0;
    # they say that this segment always starts with a specific
    # string from Adobe, namely "Photoshop 3.0\000". But some
    # old pics, with only non-IPTC data, use other strings ...
    # try all known possibilities and die if no match is found
    for my $good_id (@$APP13_PHOTOSHOP_IDS) {
	next if $this->size() < length $good_id;
	my $id = $this->read_record($UNDEF, 0, length $good_id);
	next unless $good_id eq $id;
	# store the identifier (and some additional bytes for ver.2.5 only)
	$this->store_record('Identifier', $ASCII, $offset, length $id);
	$this->store_record('Resolution', $SHORT, $offset, 4) if $id =~ /2\.5/;
    }
    # Die if no identifier was found (show first ten characters)
    $this->die('Wrong identifier ('.$this->read_record($UNDEF, 0, 10).')')
	unless $this->search_record('Identifier');
    # not much to do now, except calling repeatedly a method for
    # parsing resource data blocks. The argument is the current
    # offset, and the output is the new offset after the block
    $offset = $this->parse_resource_data_block($offset)
	while ($offset < $this->size());
    # complain if we read a bit too much ...
    $this->test_size($offset, "parsed after segment end");
}

###########################################################
# This method parses an APP13 resource data block (TODO:  #
# blocks spanning multiple APP13s). Currently, it treates #
# in details IPTC (International Press Telecommunications #
# Council) blocks, and just saves the other tags (which   #
# are, however, in general, much simpler). The only argu- #
# ment is the current offset in the data area of this     #
# object. The output is the new offset after this block.  #
# The structure of a resource data block is:              #
#---------------------------------------------------------#
#  4 bytes  type (Photoshop uses "8BIM" from v.6.0 on)    #
#  2 bytes  unique identifier (e.g. "\004\004" for IPTC)  #
#  1 byte   length of resource data block name            #
#   ....    name (padded to make size even incl. length)  #
#  4 bytes  size of resource data (following data only)   #
#   ....    data (padded to make size even)               #
#---------------------------------------------------------#
# The content of each Photoshop non-IPTC data block is    #
# transformed into a record and stored in a first-level   #
# subdirectory, depending on its type. The block type is, #
# in fact, no more supposed to be '8BIM'; however, only   #
# some known values are accepted. The IPTC data block is  #
# instead analysed in detail, and all findings are stored #
# in another (sub)directory tree. Empty subdirectories    #
# are not created.                                        #
#=========================================================#
# Ref: "Adobe Photoshop 6.0: File Formats Specifications",#
#      Adobe System Inc., ver.6.0, rel.2, November 2000.  #
# and  "\"Solo\" Image File Format. RichTIFF and its      #
#       replacement by \"Solo\" JFIF", version 2.0a,      #
#       Coatsworth Comm. Inc., Brampton, Ontario, Canada  #
###########################################################
sub parse_resource_data_block {
    my ($this, $offset) = @_;
    # An "Adobe Phostoshop" block usually starts with "8BIM".
    # Accepted values are listed in @$APP13_PHOTOSHOP_TYPE.
    my $type = $this->read_record($ASCII, $offset, 4);
    $this->die("Wrong resource data block type ($type)") 
	unless grep { $_ eq $type } @$APP13_PHOTOSHOP_TYPE;
    # then there is the block identifier
    my $identifier = $this->read_record($SHORT, $offset);
    # get the name length and the name. The length is the first byte.
    # The name can be padded so that length+name span an even number
    # of bytes. Usually the name is "" (the empty string, with length
    # 0, not "\000", which has length 1) so we get "\000\000" here.
    my $name_length = $this->read_record($BYTE, $offset);
    my $name = $this->read_record($ASCII, $offset, $name_length);
    # read the padding byte if length was even
    $this->read_record($UNDEF, $offset, 1) if ($name_length % 2) == 0;
    # the next four bytes encode the resource data size. Also in this
    # case the total size must be padded to an even number of bytes
    my $data_length = $this->read_record($LONG, $offset);
    my $need_padding = ($data_length % 2) ? 1 : 0;
    # check that there is enough data for this block; obviously, this
    # break the case of a resource data block spanning multiple segments!
    $this->test_size($offset + $data_length + $need_padding,
		     "in IPTC resource data block");
    # calculate the absolute end of the resource data block
    my $boundary = $offset + $data_length;
    # Currently, the IPTC block deserves a special treatment: repeatedly
    # read data from the data block, up to an amount equal to $data_length.
    # The IPTC-parsing routine, as usual, returns the new working offset at
    # the end. The IPTC records are written in separate subdirectories. There
    # should be no resource block description for IPTC, make it an error.
    if ($identifier eq $APP13_PHOTOSHOP_IPTC) {
	$this->die("Non-empty IPTC resource block descriptor") if $name ne '';
	$offset=$this->parse_IPTC_dataset($offset) while ($offset<$boundary); }
    # Less interesting tags are mistreated. However, they should not pollute
    # the root dir, so a subdirectory is used, which depends on $type. $name
    # is stored in the "extra" field for use at dump time.
    else { my $dirname = $APP13_PHOTOSHOP_DIRNAME . '_' . $type;
	   my $dir = $this->provide_subdirectory($dirname);
	   $this->store_record($dir,$identifier,$UNDEF,$offset,$data_length);
	   $this->search_record('LAST_RECORD',$dir)->{extra} = $name if $name;}
    # pad, if you need padding ...
    ++$offset if $need_padding;
    # that's it, return the working offset
    return $offset;
}

###########################################################
# This method parses one dataset from an APP13 IPTC block #
# and creates a corresponding record in the appropriate   #
# subdirectory (which depends on the IPTC record number). #
# The $offset argument is a pointer in the segment data   #
# area, which must be returned updated at the end of the  #
# routine. An IPTC record is a sequence of datasets,      #
# which need not be in numerical order, unless otherwise  #
# specified. Each dataset consists of a unique tag and a  #
# data field. A standard tag is used when the data field  #
# size is less than 32768 bytes; otherwise, an extended   #
# tag is used. The structure of a dataset is:             #
#---------------------------------------------------------#
#  1 byte   tag marker (must be 0x1c)                     #
#  1 byte   record number (e.g., 2 for 2:xx datasets)     #
#  1 byte   dataset number                                #
#  2 bytes  data length (< 32768 octets) or length of ... #
#  <....>   data length (> 32767 bytes only)              #
#   ....    data (its length is specified before)         #
#=========================================================#
# So, standard datasets have a 5 bytes tag; the last two  #
# bytes in the tag contain the data field length, the msb #
# being always 0. For extended datasets instead, these    #
# two bytes contain the length of the (following) data    #
# field length, the msb being always 1. The value of the  #
# msb thus distinguishes "standard" from "extended"; in   #
# digital photographies, I assume that the datasets which #
# are actually used (a subset of the standard) are always #
# standard; therefore, we are likely not to have the IPTC #
# record not spanning more than one APP13 segment.        #
#=========================================================#
# The record types defined by the IPTC-NAA standard and   #
# the corresponding dataset ranges are:                   #
#                                                         #
# Object Envelop Record:                       1:xx       #
# Application Records:                  2:xx through 6:xx #
# Pre-ObjectData Descriptor Record:            7:xx       #
# ObjectData Record:                           8:xx       #
# Post-ObjectData Descriptor Record:           9:xx       #
#                                                         #
# The Adobe "pseudo"-standard is usually restricted to    #
# the first application record, so it is unlikely, but    #
# not impossible, to find datasets outside of 2:xx.       #
# Record numbers should only be found in increasing       #
# order, but this rule is currently not enforced here.    #
#=========================================================#
# Ref: "IPTC-NAA: Information Interchange Model Version 4"#
#      Comité Internat. des Télécommunications de Presse. #
###########################################################
sub parse_IPTC_dataset {
    my ($this, $offset) = @_;
    # check that there is enough data for the dataset header
    $this->test_size($offset + 5, "in IPTC dataset");
    # each record is a sequence of variable length data sets read the
    # first four fields (five bytes), and store them in local variables.
    my $marker  = $this->read_record($BYTE , $offset);
    my $rnumber = $this->read_record($BYTE , $offset);
    my $dataset = $this->read_record($BYTE , $offset);
    my $length  = $this->read_record($SHORT, $offset);
    # check that the tag marker is 0x1c as specified by the IPTC standard
    $this->die("Invalid IPTC tag marker ($marker)") 
	if $marker ne $APP13_IPTC_TAGMARKER;
    # retrieve or create the correct subdirectory; this depends on
    # the record number (most often, it is 2, for 2:xx datasets)
    my $dir = $this->provide_subdirectory("${APP13_IPTC_DIRNAME}_$rnumber");
    # if $length has the msb set, then we are dealing with an
    # extended dataset. In this case, abort and write more code
    $this->die("IPTC extended datasets not yet supported")
	if $length & (0x01 << 15);
    # push a new record reference in the correct subdir. Use the
    # dataset number as identifier, the rest is strightforward
    # (assume that the data type is always ASCII).
    $this->store_record($dir, $dataset, $ASCII, $offset, $length);
    # return the update offset
    return $offset;
}

# successful load
1;
