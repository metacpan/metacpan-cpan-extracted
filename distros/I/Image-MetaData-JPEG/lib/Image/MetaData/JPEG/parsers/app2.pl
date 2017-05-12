###########################################################
# A Perl package for showing/modifying JPEG (meta)data.   #
# Copyright (C) 2004,2005,2006 Stefano Bettelli           #
# See the COPYING and LICENSE files for license terms.    #
###########################################################
use Image::MetaData::JPEG::data::Tables qw(:TagsAPP2);
no  integer;
use strict;
use warnings;

###########################################################
# This is the entry point for parsing APP2 segments. Such #
# application segments can host at least two formats (see #
# the called subroutines for more details):               #
#   1) Flashpix conversion information ("FPXR").          # 
#   2) ICC profiles data.                                 #
# This method decides among the various formats and then  #
# calls a specific parser. An error is issued if the      #
# metadata format is not recognised.                      #
#=========================================================#
# Ref: "Exchangeable image file format for digital still  #
#      cameras: Exif Version 2.2", JEITA CP-3451, Apr2002 #
#    Jap.Electr.Industry Develop.Assoc. (JEIDA), pag. 65  #
###########################################################
sub parse_app2 {
    my ($this) = @_;
    # If the data area begins with "FPXR\000", it contains Flashpix data
    return $this->parse_app2_flashpix()
	if $this->data(0, length $APP2_FPXR_TAG) eq $APP2_FPXR_TAG;
    # If it starts with "ICC_PROFILE", well, guess it ....
    return $this->parse_app2_ICC_profiles()
	if $this->data(0, length $APP2_ICC_TAG) eq $APP2_ICC_TAG;
    # if the segment type is unknown, generate an error
    $this->die('Incorrect identifier (' . $this->data(0, 6) . ')');
}

###########################################################
# This method parses an APP2 Flashpix extension segment,  #
# and is not really reliable, since I have only one exam- #
# ple and very badly written documentation. The FPXR      #
# structure, the worst I have ever seen, is as follows:   #
#---------------------------------------------------------#
#  5 bytes  identifier ("FPXR\000" = 0x4650585200)        #
#  1 byte   version (always zero?, it is a binary value)  #
#  1 byte   type (1=Cont. List, 2=Stream Data, 3=reserved)# 
#--- Contents List Segment -------------------------------#
#  2 bytes  Interoperability count (the list size ...)    #
#    ---------- multiple times -------------------------- #
#  4 bytes  Entity size (0xffffffff for a storage (?))    #
#     ...   Storage/Stream name (null termin., Unicode)   #
# 16 bytes  Entity class ID (for storages) (var. size ?)  #
#--- Stream Data Segment ---------------------------------#
#  2 bytes  index in the Contents List                    #
#  4 bytes  offset to the first byte in the stream (?)    #
#     ...   the actual data stream (to the end?)          #
#=========================================================#
# Ref: "Exchangeable image file format for digital still  #
#      cameras: Exif Version 2.2", JEITA CP-3451, Apr2002 #
#    Jap.Electr.Industry Develop.Assoc.(JEIDA), pag.65-67 #
###########################################################
sub parse_app2_flashpix {
    my ($this) = @_;
    my $offset = 0;
    # at least 7 bytes for the identifier, its version and its type
    $this->test_size(7, "FPXR header too small");
    # decode the identifier (get its length from $APP2_FPXR_TAG)
    my $identifier = $this->store_record
	('Identifier', $ASCII, $offset, length $APP2_FPXR_TAG)->get_value();
    # die if it is not correct
    $this->die("Incorrect identifier ($identifier)")
	if $identifier ne $APP2_FPXR_TAG;
    # decode the version number (is this always zero?) and the data type
    $this->store_record('Version', $BYTE, $offset);
    my $type = $this->store_record('FPXR_type', $BYTE, $offset)->get_value();
    # data type equal to 1 means we are dealing with a Contents List
    # structure, listing the storages and streams for the Flashpix image.
    if ($type == 1) {
	# the first two bytes select the number of entries in the list
	my $count = $this->read_record($SHORT, $offset);
	for (1..$count) {
	    # create a separate subdir for each entry (stupid ?), then
	    # get the entity size and default value (the size refers to
	    # what we are going to find in future APP2 segments!).
	    my $subdir = $this->provide_subdirectory('Entity_' . $_);
	    my $size = $this->store_record($subdir, 'Size', $LONG, $offset);
	    $this->store_record($subdir, 'DefaultValue', $BYTE, $offset);
	    # the following entry is a Unicode string (16 bits --> 1 char)
	    # in little endian format. It terminates with a Unicode null
	    # char, i.e., "\000\000". Find its length, then store it. The
	    # string is invalid if it does not begin with Unicode "/".
	    my $pos=0; $pos+=2 while $this->data($offset+$pos,2) ne "\000\000";
	    $this->die('Invalid Storage/Stream name (not beginning with /)')
		if $this->data($offset, 2) ne "/\000";
	    $this->store_record($subdir, 'Name', $ASCII, $offset, $pos+2);
	    # if $size is 0xffffffff, we are dealing with a Storage
	    # Interoperability Field; I don't know what this means, but
	    # at this point there should be an "Entity class ID" (16 bytes)
	    $this->store_record($subdir, 'Class_ID', $UNDEF, $offset, 16)
		if $size == 0xffffffff;
	} } 
    # data type equal to 2 means we are dealing with a Stream Data
    # segment (there can be more than one such segments).
    elsif ($type == 2) {
	$this->store_record('ContentsIndex', $SHORT, $offset);
	$this->store_record('StreamOffset', $LONG, $offset);
	$this->store_record('Data', $UNDEF, $offset, $this->size() - $offset);
    }
    # type 3 is reserved for the future (let me know ...)
    elsif ($type == 3) {
	$this->store_record('Unknown', $UNDEF, $offset,$this->size()-$offset);}
    # a type different from 1, 2 or 3 is not valid.
    else { $this->die("Unknown FPXR type ($type)"); }
    # check that there are no spurious data in the segment
    $this->test_size(-$offset, "unknown data at segment end");
}

###########################################################
# This method parses an APP2 ICC_PROFILE segment. The     #
# profile is defined as a header followed by a tag table  #
# followed by a series of tagged elements. This routine   #
# parses the overall structure and the profile header,    #
# the other tags are read by parse_app2_ICC_tags(). The   #
# ICC segment structure is as follows:                    #
#---------------------------------------------------------#
#  5 bytes  identifier ("FPXR\000" = 0x4650585200)        #
#  1 byte   sequence number of the chunck (starting at 1) #
#  1 byte   total number of chunks                        #
#------- Profile header ----------------------------------#
#  4 bytes  profile size (this includes header and data)  #
#  4 bytes  CMM type signature                            #
#  4 bytes  profile version number                        #
#  4 bytes  profile/device class signature                #
#  4 bytes  color space signature                         #
#  4 bytes  profile connection space (PCS) signature      #
# 12 bytes  date and time this profile was created        #
#  4 bytes  profile file signature                        #
#  4 bytes  profile primary platform signature            #
#  4 bytes  flags for CMM profile options                 #
#  4 bytes  device manifacturer signature                 #
#  4 bytes  device model signature                        #
#  8 bytes  device attributes                             #
#  4 bytes  rendering intent                              #
# 12 bytes  XYZ values of the illuminant of the PCS       #
#  4 bytes  profile creator signature                     #
# 16 bytes  profile ID checksum                           #
# 28 bytes  reserved for future expansion (must be zero)  #
#------- Tag table ---------------------------------------#
# see parse_app2_ICC_tags()                               #
#=========================================================#
# Since ICC profile data can easily exceed 64KB, there is #
# a mechanism to divide the profile into smaller chunks.  #
# This is the sequence number; every chunk must show the  #
# same value for the total number of chunks.              #
#=========================================================#
# Ref: "Specification ICC.1:2003-09, File Format for Co-  #
#       lor Profiles (ver. 4.1.0)", Intern.Color Consort. #
###########################################################
sub parse_app2_ICC_profiles {
    my ($this) = @_;
    my $offset = 0;
    # get the length of the APP2 ICC identifier; then calculate
    # the profile header offset (there are two more bytes)
    my $id_size = length $APP2_ICC_TAG;
    my $header_base = $id_size + 2;
    # at least $header_base + 128 bytes (profile header) to start 
    $this->test_size($header_base + 128, "ICC profile header too small");
    # decode the identifier (get its length from $APP2_FPXR_TAG)
    my $identifier = $this->store_record
	('Identifier', $ASCII, $offset, $id_size)->get_value();
    # die if it is not correct
    $this->die("Incorrect identifier ($identifier)") 
	if $identifier ne $APP2_ICC_TAG;
    # read the sequence number and the total number of chunks
    $this->store_record('SequenceNumber', $BYTE, $offset);
    $this->store_record('TotalNumber',    $BYTE, $offset);
    # read the profile size and check with the real size
    # remember to include the (identifier + chunks) bytes
    my $size = $this->read_record($LONG, $offset);
    $this->test_size(-($size + $header_base), "Incorrect ICC data size");
    # prepare a subdirectory for the profile header
    my $sd = $this->provide_subdirectory('ProfileHeader');
    # read all other entries in the profile header
    $this->store_record($sd, 'CMM_TypeSignature',        $ASCII, $offset, 4 );
    $this->store_record($sd, 'ProfileVersionNumber',     $UNDEF, $offset, 4 );
    $this->store_record($sd, 'ClassSignature',           $ASCII, $offset, 4 );
    $this->store_record($sd, 'ColorSpaceSignature',      $ASCII, $offset, 4 );
    $this->store_record($sd, 'ConnectionSpaceSignature', $ASCII, $offset, 4 );
    $this->store_record($sd, 'Year',                     $SHORT, $offset    );
    $this->store_record($sd, 'Month',                    $SHORT, $offset    );
    $this->store_record($sd, 'Day',                      $SHORT, $offset    );
    $this->store_record($sd, 'Hour',                     $SHORT, $offset    );
    $this->store_record($sd, 'Minute',                   $SHORT, $offset    );
    $this->store_record($sd, 'Second',                   $SHORT, $offset    );
    $this->store_record($sd, 'ProfileFileSignature',     $ASCII, $offset, 4 );
    $this->store_record($sd, 'PrimaryPlatformSignature', $ASCII, $offset, 4 );
    $this->store_record($sd, 'CMM_ProfileFlags',         $LONG,  $offset    );
    $this->store_record($sd, 'DeviceManifactSignature',  $ASCII, $offset, 4 );
    $this->store_record($sd, 'DeviceModelSignature',     $ASCII, $offset, 4 );
    $this->store_record($sd, 'DeviceAttributes',         $UNDEF, $offset, 8 );
    $this->store_record($sd, 'RenderingIntent',          $LONG,  $offset    );
    $this->store_record($sd, 'XYZ_PCS_Illuminant',       $UNDEF, $offset, 12);
    $this->store_record($sd, 'ProfileCreatorSignature',  $ASCII, $offset, 4 );
    $this->store_record($sd, 'ProfileID_Checksum',       $UNDEF, $offset, 16);
    # the last 28 bytes in the profile header are reserved for
    # future use, and should contain only zero.
    my $reserved = $this->read_record($UNDEF, $offset, 28);
    $this->die('Non-zero reserved bytes in profile header')
	if $reserved ne "\000" x 28;
    # call another method knowing how to read the remaining tags
    # (it only needs to know the current offset and where is the
    # beginning of the profile header)
    return $this->parse_app2_ICC_tags($offset, $header_base);
}

###########################################################
# This method parses the tag table of an APP2 ICC_PROFILE #
# segment (it complements parse_app2_ICC_profiles()). See #
# that routine for more details. The arguments are the    #
# current offset in the segment data area and the start   #
# of the profile header with respect to the beginning of  #
# the segment data area. There are no checks on the over- #
# all size, since it is assumed that this was already     #
# controlled by the calling routine. The tag table        #
# structure is as follows:                                #
#---------------------------------------------------------#
#  4 bytes  tag count                                     #
#           ---------- multiple times ------------------- #
#  4 bytes  tag signature (a unique number)               #
#  4 bytes  tag offset from the profile header start      #
#  4 bytes  tag size                                      #
#------ Data area of a tag -------------------------------#
#  4 bytes  ICC tag type (an ASCII string)                #
#  4 bytes  reserved for the future ("\000\000\000\000")  #
#    ....   real data area (various encodings).           #
#---------------------------------------------------------#
# The first tag data area must immediately follow the tag #
# table. All tagged element data must be padded with      #
# nulls by no more than three pad bytes to reach a four   #
# bytes boundary. We only store the final part of the tag #
# data area in the record (the ICC type is saved in its   #
# extra field). See the code for more details.            #
#=========================================================#
# Ref: "Specification ICC.1:2003-09, File Format for Co-  #
#       lor Profiles (ver. 4.1.0)", Intern.Color Consort. #
###########################################################
sub parse_app2_ICC_tags {
    my ($this, $offset, $header_base) = @_;
    # read the number of tags in the tag table (don't store it)
    my $tags = $this->read_record($LONG, $offset);
    # prepare a subdirectory for the tag table
    my $tag_table = $this->provide_subdirectory('TagTable');
    # repeat the tag-reading algorithm $tags time
    for (1..$tags) {
	# the 12 bytes in the tag table entry contain the tag code
	# (which we are going to use as record key), the pointer to
	# the tag data with respect to the profile header beginning
	# and the size of this data area. Read and don't store.
	my $tag_code   = $this->read_record($LONG, $offset);
	my $tag_offset = $this->read_record($LONG, $offset);
	my $tag_size   = $this->read_record($LONG, $offset);
	# the first 8 bytes in the tag data area are special; the first
	# 4 bytes specify the "ICC type", the following 4 must be zero.
	# Read, check the condition, but don't store.
	my $tag_desc   = $this->data($header_base + $tag_offset    , 4);
	my $tag_pad    = $this->data($header_base + $tag_offset + 4, 4);
	$this->die('Non-zero padding in ICC tag') 
	    if $tag_pad ne "\000\000\000\000";
	# adjust the tag size and offset to reflect the 8 bytes we read.
	# also adjust the offset by adding the profile header base
	$tag_size -= 8; $tag_offset += 8 + $header_base;
	# a few ICC tag types can be shown with something more
	# specific than the UNDEF type (which remains the default)
	my $tag_type = $UNDEF;
	$tag_type = $ASCII  if $tag_desc =~ /text|sig /;
	$tag_type = $BYTE   if $tag_desc =~ /ui08/;
	$tag_type = $SHORT  if $tag_desc =~ /ui16|dtim/;
	$tag_type = $LONG   if $tag_desc =~ /ui32|XYZ |view/;
	# depending on the tag type, calculate its length in bytes and
	# therefore the number of elements in the data area (the count).
	# If the type is variable-length (i.e., if get_size returns
	# zero), $tag_count must be indeed equal to $tag_size.
	my $tag_length = Image::MetaData::JPEG::Record->get_size($tag_type, 1);
	my $tag_count  = ($tag_length == 0)? $tag_size : $tag_size/$tag_length;
	# now, store the content of the tag data area (minus the first
	# 8 bytes) as a record of given key, type and count. Store the
	# record in the tag table subdirectory.
	$this->store_record($tag_table, $tag_code, $tag_type,
			    \ $this->data($tag_offset, $tag_size), $tag_count);
	# also store the ICC tag type in the record "extra" field
	$this->search_record('LAST_RECORD', $tag_table)->{extra} = $tag_desc;
    }
}

# successful load
1;
