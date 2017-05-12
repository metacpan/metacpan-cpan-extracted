###########################################################
# A Perl package for showing/modifying JPEG (meta)data.   #
# Copyright (C) 2004,2005,2006 Stefano Bettelli           #
# See the COPYING and LICENSE files for license terms.    #
###########################################################
use Image::MetaData::JPEG::data::Tables qw(:TagsAPP1_Exif);
no  integer;
use strict;
use warnings;

###########################################################
# This method parses a standard (Exif) APP1 segment. Such #
# an application segment is used by Exif JPEG files to    #
# store metadata, so that they do not conflict with those #
# of the JFIF format (which uses the APP0 segment).       #
# The structure of an Exif APP1 segment is as follows:    #
#---------------------------------------------------------#
#  6 bytes  identifier ('Exif\000\000' = 0x457869660000)  #
#  2 bytes  TIFF header endianness ('II' or 'MM')         #
#  2 bytes  TIFF header signature (a fixed value = 42)    #
#  4 bytes  TIFF header: offset of 0th IFD                #
# ...IFD... 0th IFD (main image)                          #
# ...IFD... SubIFD (EXIF private tags) linked by IFD0     #
# ...IFD... Interoperability IFD, linked by SubIFD        #
# ...IFD... GPS IFD (optional) linked by IFD0             #
# ...IFD... 1st IFD (thumbnail) linked by IFD0            #
# ...IFD... Thumbnail image (0xffd8.....ffd9)             #
#=========================================================#
# The offset of the 0th IFD in the TIFF header, as well   #
# as IFD links in the IFDs, is given with respect to the  #
# beginning of the TIFF header (i.e. the address of the   #
# 'MM' or 'II' pair). This means that if the 0th IFD be-  #
# gins (as usual) immediately after the end of the TIFF   #
# header, the offset value is 8.                          #
#=========================================================#
# An Exif file can contain a thumbnail, usually located   #
# next to the 1st IFD. There are 3 possible formats: JPEG #
# (only this is compressed), RGB TIFF, and YCbCr TIFF. It #
# seems that JPEG and 160x120 pixels are recommended for  #
# Exif ver. 2.1 or higher (mandatory for DCF files).      #
# Since the segment size for APP1 is recorded in 2 bytes, #
# the thumbnail are limited to 64KB minus something.      #
#---------------------------------------------------------#
# A JPEG thumbnail is selected by Compression(0x0103) = 6.#
# In this case, one can get the thumbnail offset from the #
# JPEGInterchangeFormat(0x0201) tag, and the thumbnail    #
# length from the JPEGInterchangeFormatLength(0x0202) tag.#
#---------------------------------------------------------#
# An uncompressed (TIFF image) thumbnail is selected by   #
# Compression(0x0103) = 1. The thumbnail offset and size  #
# are to be read from StripOffset(0x0111) and (the sum of)#
# StripByteCounts(0x0117). For uncompressed thumbnails,   #
# PhotometricInterpretation(0x0106) = 2 means RGB format, #
# while = 6 means YCbCr format.                           #
#=========================================================#
# Ref: http://park2.wakwak.com/                           #
#             ~tsuruzoh/Computer/Digicams/exif-e.html     #
# and "Exchangeable image file format for digital still   #
#      cameras: Exif Version 2.2", JEITA CP-3451, Apr2002 #
#   Japan Electronic Industry Development Assoc. (JEIDA)  #
###########################################################
sub parse_app1_exif {
    my ($this) = @_;
    # decode and save the identifier (it should be 'Exif\000\000'
    # for an APP1 segment) and die if it is not correct.
    my $identifier = $this->store_record
	('Identifier', $ASCII, 0, length $APP1_EXIF_TAG)->get_value();
    $this->die("Incorrect identifier ($identifier)")
	if $identifier ne $APP1_EXIF_TAG;
    # decode the TIFF header (records added automatically in root);
    # it should be located immediately after the identifier
    my ($tiff_base, $ifd0_link, $endianness) = 
	$this->parse_TIFF_header(length $identifier);
    # Remember to convert the ifd0 offset with the TIFF header base.
    my $ifd0_offset = $tiff_base + $ifd0_link;
    # locally set the current endianness to what we have found
    local $this->{endianness} = $endianness;
    # parse all records in the 0th IFD. Inside it, there might be a link
    # to the EXIF private tag block (SubIFD), which contains all you want
    # to know about how the shot was shot. Perversely enough, the SubIFD
    # can nest two other IFDs, namely the "Interoperabiliy IFD" and the
    # "MakerNote IFD". Decoding the Maker Note is likely to fail, because
    # most vendors do not publish their MakerNote format. However, if the
    # note is decoded, the findings are written in a new subdirectory.
    my $ifd1_link = $this->parse_ifd('IFD0', $ifd0_offset, $tiff_base);
    # Remember to convert the ifd1 offset with the TIFF header base
    # (if $ifd1_link is zero, there is no next IFD, set to undef)
    my $ifd1_offset = $ifd1_link ? $tiff_base + $ifd1_link : undef;
    # same thing for the 1st IFD. In this case the test is not on next_link
    # being defined, but on it being zero or not. The returned values is
    # forced to be zero (this is the meaning of the final '1' in parse_ifd)
    $this->parse_ifd('IFD1', $ifd1_offset, $tiff_base, 1) if $ifd1_offset;
    # look for the compression tag (thumbnail type record). If it is
    # present, we definitely need to look for the thumbnail (boring)
    my $th_type = $this->search_record_value('IFD1', $APP1_TH_TYPE);
    if (defined $th_type) {
	# thumbnail type should be either TIFF or JPEG. Die if not known
	$this->die("Unknown thumbnail type ($th_type)")
	    if $th_type != $APP1_TH_TIFF && $th_type != $APP1_TH_JPEG;
	# calculate the thumbnail location and size
	my ($thumb_link, $thumb_size) =
	    map { $this->search_record_value('IFD1', $_) }
	      $th_type == $APP1_TH_TIFF
	        ? ($THTIFF_OFFSET, $THTIFF_LENGTH) 
	        : ($THJPEG_OFFSET, $THJPEG_LENGTH);
	# Some pictures declare they have a thumbnail, but there is
	# no thumbnail link for it (maybe this is due to some program
	# which strips the thumbnail out without completely removing
	# the 1st IFD). Treat this case as if $th_type was undefined.
	goto END_THUMBNAIL unless defined $thumb_link;
	# point the current offset to the thumbnail
	my $offset = $tiff_base + $thumb_link;
	# sometimes, we have broken pictures with an actual size shorter
	# than $thumb_size; nonetheless, the thumbnail is often valid, so
	# this case deserves only a warning if the difference is not too
	# large (currently, 10 bytes), but $thumb_size must be updated. 
	my $remaining = $this->size() - $offset;
	if ($thumb_size > $remaining) {
	    $this->die("Large mismatch ($remaining instead of $thumb_size) ",
		       "in thumbnail size") if $thumb_size - $remaining > 10;
	    $this->warn("Predicted thumbnail size ($thumb_size) larger than "
			. "available data size ($remaining). Correcting ...");
	    $thumb_size = $remaining; }
	# store the thumbnail (if present)
	$this->store_record('ThumbnailData', $UNDEF, $offset, $thumb_size) 
	    if $thumb_size > 0;
      END_THUMBNAIL:
    }
}

###########################################################
# This method parses a TIFF header, which can be found,   #
# for instance, in APP1/APP3 segments. The first argument #
# is the start address of the TIFF header; the second one #
# (optional) is the record subdirectory where parsed      #
# records should be saved (defaulting to the root dir).   #
# The structure is as follows:                            #
#---------------------------------------------------------#
#  2 bytes  TIFF header endianness ('II' or 'MM')         #
#  2 bytes  TIFF header signature (a fixed value = 42)    #
#  4 bytes  TIFF header: offset of 0th IFD                #
#---------------------------------------------------------#
# The returned values are: the offset of the TIFF header  #
# start (this is usually a base for many other offsets),  #
# the offset of the 0-th IFD with respect to the TIFF     #
# header start, and the endianness.                       #
#=========================================================#
# The first two bytes of the TIFF header give the byte    #
# alignement (endianness): either 0x4949='II' for "Intel" #
# type alignement (small endian) or 0x4d4d='MM' for "Mo-  #
# torola" type alignement (big endian). An EXIF block is  #
# the only part of a JPEG file whose endianness is not    #
# fixed to big endian (sigh!)                             #
#=========================================================#
# and "Exchangeable image file format for digital still   #
#      cameras: Exif Version 2.2", JEITA CP-3451, Apr2002 #
#   Japan Electronic Industry Development Assoc. (JEIDA)  #
###########################################################
sub parse_TIFF_header {
    my ($this, $offset, $dirref) = @_;
    # die if the $offset is undefined
    $this->die('Undefined offset') unless defined $offset;
    # set the subdir reference to the root if it is undefined
    $dirref = $this->{records} unless defined $dirref;
    # at least 8 bytes for the TIFF header (remember you
    # should count them starting from $offset)
    $this->test_size($offset + 8, "not enough space for the TIFF header");
    # save the current offset for later use (TIFF header starts here)
    my $tiff_base = $offset;
    # decode the endianness (either 'II' or 'MM', 2 bytes); this is
    # not an $ASCII string (no terminating null character), so it is
    # better to use the $UNDEF type; die if it is unknown
    my $endianness = $this->store_record
	($dirref, 'Endianness', $UNDEF, $offset, 2)->get_value();
    $this->die("Unknown endianness ($endianness)")
	if $endianness ne $BIG_ENDIAN && $endianness ne $LITTLE_ENDIAN;
    # change (locally) the endianness value
    local $this->{endianness} = $endianness;
    # decode the signature (42, i.e. 0x002a), die if it is unknown
    my $signature = $this->store_record
	($dirref, 'Signature', $SHORT, $offset)->get_value();
    $this->die("Incorrect signature ($signature)")
	if $signature != $APP1_TIFF_SIG;
    # decode the offset of the 0th IFD: this is usually 8, but we are
    # not going to assume it. Do not store the record (it is uninteresting)
    my $ifd0_link = $this->read_record($LONG, $offset); 
    # return all relevant values in a list
    return ($tiff_base, $ifd0_link, $endianness);
}

###########################################################
# This method parses an IFD block, like those found in    #
# the APP1 or APP3 segments. The arguments are: the name  #
# of the block, the absolute address of the start of the  #
# block (in the segment's data area) and the value of the #
# offset base (i.e., the address which all other offsets  #
# found in the interoperability arrays are relative to;   #
# normally, a TIFF header base). The following arguments  #
# are optional: the first one specifies how the next_link #
# pointer is to be treated ('0': the pointer is read;     #
# '1': the pointer is read and a warning is issued if it  #
# is non-zero; '2': the pointer is not read), and the     #
# second one whether the prediction mechanism for intero- #
# perability offsets should be used or not. The return    #
# value is the next_link pointer.                         #
# ------------------------------------------------------- #
# structure of an IFD:                                    #
#     2  bytes    Number n of Interoperability arrays     #
#    12n bytes    the n arrays (12 bytes each)            #
#     4  bytes    link to next IFD (can be zero)          #
#   .......       additional data area                    #
# ======================================================= #
# The block name is indeed a '@' separated list of names, #
# which are to be interpreted in sequence; for instance   #
# "IFD0@SubIFD" means that in $this->{records} there is a #
# REFERENCE record with key "IFD" and value $dirref; then #
# in $$dirref there is a REFERENCE record with key equal  #
# to "SubIFD" and so on ...                               #
# ------------------------------------------------------- #
# After the execution of this routine, a new REFERENCE    #
# record will be present, whose value is a reference to   #
# a list of all the entries in the IFD. If $offset is un- #
# defined, this routine returns immediately (in this way  #
# you do not need to test it before). No next_link's are  #
# tolerated in the underlying subdirectories. Deeper      #
# IFD's are analysed by parse_ifd_children.               #
# ------------------------------------------------------- #
# There is now a prediction and correction mechanism for  #
# the offsets in the interoperability arrays. The simple  #
# assumption is that the absolute value of offsets can be #
# wrong, but their difference is always right, so, if you #
# get the first one right ... a good bet is the address   #
# of the byte immediately following the next_IFD link.    #
# The @$prediction array is used to exchange information  #
# with parse_interop(): [0] = use predictions to rewrite  #
# addresses (if set); [1] = value for next address pre-   #
# diction; [2] = old interoperability array address.      #
###########################################################
sub parse_ifd {
    my ($this, $dirnames, $offset, $base, $next, $use_prediction) = @_;
    # if $offset is undefined, return immediately
    return unless defined $offset;
    # if next is undefined, set it to zero
    $next = 0 unless defined $next;
    # the first two bytes give the number of Interoperability arrays.
    # Don't insert this value into the record list, just read it.
    my $records = $this->read_record($SHORT, $offset);
    # create/retrieve the appropriate record list and save its
    # reference. The list is specified by a '@' separated list
    # of dir names in $dirnames (to be interpreted in sequence)
    my $dirref = $this->provide_subdirectory($dirnames);
    # initialise the structure for address prediction (note that the 4
    # bytes of the "next link" must be added only if $next is < 2)
    my $remote = $offset + 12*$records; $remote += 4 if $next < 2;
    my $prediction = [$use_prediction, $remote, undef];
    # parse all the records in the IFD; additional data might be referenced
    # through offsets relative to the address base (usually, the tiff header
    # base). This populates the $$dirref list with IFD records.
    $offset = $this->parse_interop
	($offset, $base, $dirref, $prediction) for (1..$records);
    # after the IFD records there can be a link to the next IFD; this
    # is an unsigned long, i.e. 4 bytes. If there is no next IFD, these
    # bytes are 0x00000000. If $next is 2, these four bytes are absent.
    my $next_link = ($next > 1) ? undef : $this->read_record($LONG, $offset);
    # if $next is true and we have a non-zero "next link", complain
    $this->warn("next link not zero") if $next && $next_link;
    # take care of possible subdirectories
    $this->parse_ifd_children($dirnames, $base, $offset);
    # return the next IFD link
    return $next_link;
}

###########################################################
# This method analyses the subdirectories of an IFD, once #
# the basic IFD analysis is complete. The arguments are:  #
# the name of the "parent" IFD, the value of the offset   #
# base and the address of the 1st byte after the next_IFD #
# link in the parent IFD (this is used only to warn if    #
# smaller addresses are found, which is usually an indi-  #
# cation of data corruption). See parse_ifd for further   #
# details on these arguments and the IFD structure.       #
# ------------------------------------------------------- #
# Deeper IFD's are searched for and inserted. A subdir is #
# indicated by a $LONG record whose tag is present in     #
# %IFD_SUBDIRS. The goal of this routine is to create a   #
# $REFERENCE record and parse the subdir into the array   #
# pointed by it; the originating offset record is removed #
# since it contains very fragile info now (its name is    #
# saved in the "extra" field of the $REFERENCE).          #
# ------------------------------------------------------- #
# Treatment of MakerNotes is triggered here: the approach #
# is almost identical to that for deeper IFD's, but the   #
# recursive call to parse_ifd is replaced by a call to    #
# parse_makernote (with some arguments differing).        #
###########################################################
sub parse_ifd_children {
    my ($this, $dirnames, $base, $old_offset) = @_;
    # retrieve the record list of the "parent" IFD
    my $dirref = $this->search_record_value($dirnames);
    # take care of possible subdirectories. First, create a
    # string with the current IFD or sub-IFD path name.
    my $path = join '@', $this->{name}, $dirnames;
    # Now look into %IFD_SUBDIRS to see if this path is a valid key; if
    # it is (i.e. subdirs are possible), inspect the relevant mapping hash
    if (exists $IFD_SUBDIRS{$path}) {
	my $mapping = $IFD_SUBDIRS{$path};
	# $tag is a numerical value, not a string
	foreach my $tag (sort keys %$mapping) {
	    # don't parse if there is no such subdirectory
	    next unless (my $record = $this->search_record($tag, $dirref));
	    # get the name and location of this secondary IFD
	    my $new_dirnames = join '@', $dirnames, $$mapping{$tag};
	    my $new_offset   = $base + $record->get_value();
	    # although there is no prescription I know about forbidding to
	    # jump back, this situation usually indicates a corrupted file
	    $this->die('Jumping back') if $new_offset < $old_offset;
	    # parse the new IFD (MakerNote records are analysed here, with a
	    # special routine; the data size is contained in the extra field).
	    my @common = ($new_dirnames, $new_offset, $base);
	    $tag == $MAKERNOTE_TAG
		? $this->parse_makernote(@common, $record->{extra})
		: $this->parse_ifd      (@common, 1);
	    # mark the record containing the offset to the newly created
	    # IFD by setting its "extra" field. This record isn't any more
	    # interesting after we have used it, and should be recalculated
	    # every time we change the Exif data area.
	    $record->{extra} = "deleteme";
	    # Look for the new IFD referece (it should be the last record
	    # in the current subdirectory) and set its "extra" field to
	    # the tag name of $record, just for reference
	    $this->search_record('LAST_RECORD', $dirref)->{extra} =
		JPEG_lookup($path, $tag); } }
    # remove all records marked for deletion in the current subdirectory
    # (remember that "extra" is most of the time undefined).
    @$dirref = grep { ! $_->{extra} || $_->{extra} ne "deleteme" } @$dirref;
}

###########################################################
# This method parses an IFD Interoperability array.       #
#=========================================================#
# Each Interoperability array consists of four elements:  #
#     bytes 0-1   Tag          (a unique 2-byte number)   #
#     bytes 2-3   Type         (one out of 12 types)      #
#     bytes 4-7   Count        (the number of values)     #
#     bytes 8-11  Value Offset (value or offset)          #
#                                                         #
# Types are the same as for the Record class. The "value  #
# offset" contains an offset from the address base where  #
# the value is recorded (the TIFF header base usually).   #
# It contains the actual value if it is not larger than   #
# 4 bytes. If the value is shorter than 4 bytes, it is    #
# recorded in the lower end of the 4-byte area (smaller   #
# offsets). This method returns the offset value summed   #
# to the number of bytes which were read ($offset + 12).  #
# ------------------------------------------------------- #
# The MakerNote Interoperability array is now intercepted #
# and stored as one $LONG (instead of many $UNDEF bytes); #
# the MakerNote content is supposed to be processed at a  #
# later time, and this record is supposed to be temporary.#
# The data area size is saved in the extra field.         #
# ------------------------------------------------------- #
# New "prediction" structure to help detecting corrupted  #
# MakerNotes: [0] = use predictions to rewrite addresses  #
# (if set); [1] = the prediction for the next data area   #
# (for size > 4); [2] = this element is updated with the  #
# address found in the interoperability array.            #
###########################################################
sub parse_interop {
    my ($this, $offset, $offset_base, $dirref, $pred) = @_;
    # the data area must be at least 12 bytes wide
    $this->test_size(12, "initial bytes check");
    # read the content of the four fields of the Interoperability array,
    # without inserting them in any record list. Interpret the last field
    # as an unsigned long integer, even if this is not the case
    my $tag     = $this->read_record($SHORT, $offset);
    my $type    = $this->read_record($SHORT, $offset);
    my $count   = $this->read_record($LONG , $offset);
    my $doffset = $this->read_record($LONG , $offset);
    # the MakerNote tag should have been designed as a 'LONG' (offset),
    # not as 'UNDEFINED' data. "Correct" it and leave parsing for other
    # routines; ($count is saved in the "extra field, for later reference)
    $this->store_record($dirref, $tag, $LONG, $offset-4, 1)->{extra} =
	$count, goto PARSE_END if $tag == $MAKERNOTE_TAG;
    # ask the record class to calculate the number of bytes necessary
    # to store the value (the type size times the number of items).
    my $size = Image::MetaData::JPEG::Record->get_size($type, $count);
    # if $size is zero, it means that the Record type is variable-length;
    # in this case, $size should be given by $count
    $size = $count if $size == 0;
    # If $size is larger than 4, calculate the real data area offset
    # ($doffset) in the file by adding the offset base; however, if
    # $size is less or equal to 4 we must point it to its own 4 bytes.
    $doffset = ($size < 5) ? ($offset - 4) : ($offset_base + $doffset);
    # if there is a remote data area, and the prediction mechanism is
    # enabled, use the prediction structure to set the value of $doffset
    # (then, update the structure); if the mechanism is disabled, check
    # that $doffset does not point before the first prediction (this is
    # very likely an address corruption).
    if ($size > 4) {
	if ($$pred[0]) { 
	    my $jump = defined $$pred[2] ? ($doffset - $$pred[2]) : 0;
	    $$pred[1]+=$jump; ($$pred[2], $doffset) = ($doffset, $$pred[1]); }
	else { $this->die('Corrupted address') if $doffset < $$pred[1] } }
    # Check that the data area exists and has the correct size (this
    # avoids trying to read it if $doffset points out of the segment).
    $this->test_size($doffset + $size, 'Interop. array data area not found');
    # insert the Interoperability array value into its sub-directory
    $this->store_record($dirref, $tag, $type, $doffset, $count);
    # return the updated $offset
  PARSE_END: return $offset;
}

###########################################################
# This method tries to parse a MakerNote block. The first #
# argument is the beginning of the name of a MakerNote    #
# subdirectory to be completed with the actual format,    #
# e.g. '_Nikon_2'. The other arguments are: the absolute  #
# address of the MakerNote block start, the address base  #
# of the SubIFD (this should be the TIFF header base) and #
# the size of the MakerNote block.                        #
# ======================================================= #
# The MakerNote tag is read by a call to parse_interop in #
# the IFD0@SubIFD; however, only the offset and size of   #
# the MakerNote data area is read there -- the real pro-  #
# cessing is done here (this method is called during the  #
# analysis of IFD subdirectories in parse_ifd).           #
###########################################################
sub parse_makernote {
    my ($this, $dirnames, $mknt_offset, $base, $mknt_size) = @_;
    # A MakerNote is always in APP1@IFD0@SubIFD; stop immediately
    # if $dirnames disagrees with this assumption.
    $this->die("Invalid \$dirnames ($dirnames)") 
	unless $dirnames =~ '^IFD0@SubIFD@[^@]*$';
    # get the primary IFD reference and try to extract the maker
    # (setup a fake string if this field is not found)
    my $ifd0 = $this->search_record_value('IFD0');
    my $mknt_maker = $this->search_record_value
	(JPEG_lookup('APP1@IFD0@Make'), $ifd0) || 'Unknown Maker';
    # try all possible MakerNote formats (+ catch-all rule)
    my $mknt_found = undef;
    for my $format (sort keys %$HASH_MAKERNOTES) {
	# this quest must stop at the first positive match
	next if $mknt_found;
	# extract the property table for this MakerNote format
	# (and skip it if it is only a temporary placeholder)
	my $hash = $$HASH_MAKERNOTES{$format};
	next if exists $$hash{ignore};
	# get the maker and signature for this format
	my $format_signature = $$hash{signature};
	my $format_maker     = $$hash{maker};
	# skip if the maker or the signature is incompatible (the
	# signature test is the initial part of the data area against
	# a regular expression: save the match for later reference)
	my $incipit_size = $mknt_size < 50 ? $mknt_size : 50;
	my $incipit = $this->read_record($UNDEF, 0+$mknt_offset,$incipit_size);
	next unless $mknt_maker =~ /$format_maker/;
	next unless $incipit =~ /$format_signature/;
	my $signature = $1; my $skip = length $signature;
	# OK, we opted for this format
	$mknt_found = 1;
	# if the previous tests pass, it is time to fix the format and
	# to create an appropriate subdirectory for the MakerNote records
	my $mknt_dirname = $dirnames.'_'.$format;
	my $mknt_dir     = $this->provide_subdirectory($mknt_dirname);
	# prepare also a special subdirectory for pseudofields
	my $mknt_spcname = $mknt_dirname.'@special';
	my $mknt_spc     = $this->provide_subdirectory($mknt_spcname);
	# the MakerNote's endianness can be different from that of the IFD;
	# if a value is specified for this format, set it; otherwise, try to
	# detect it by testing the first byte after the signature (preferred).
	my $it_looks_big_endian = $this->data($mknt_offset+$skip, 1) eq "\000";
	my $mknt_endianness = exists $$hash{endianness} ? $$hash{endianness} :
	    $it_looks_big_endian ? $BIG_ENDIAN : $LITTLE_ENDIAN;
	# in general, the MakerNote's next-IFD link is zero, but some
	# MakerNotes do not even have these four bytes: prepare the flag
	my $next_flag = exists $$hash{nonext} ? 2 : 1;
	# in general, MakerNote's offsets are computed from the APP1 segment
	# TIFF base; however, some formats compute offsets from the beginning
	# of the MakerNote itself: prepare an alternative base if necessary
	my $mknt_base = exists $$hash{mkntstart} ? $mknt_offset : $base;
	# some MakerNotes have a TIFF header on their own, freeing them
	# from the relocation problem; values from this header overwrite
	# the previously assigned values; records are saved in $mknt_dir.
	if (exists $$hash{mkntTIFF}) {
	    ($mknt_base, my $ifd_link, $mknt_endianness)
		= $this->parse_TIFF_header($mknt_offset + $skip, $mknt_spc);
	    # update $skip to point to the beginning of the IFD
	    $skip += $ifd_link; }
	# calculate the address of the beginning of the IFD (both with
	# and without a TIFF header) or of an unstructured data area.
	my $data_offset = $mknt_offset + $skip;
	# Store the special MakerNote information in a special subdirectory
	# (for instance, the raw MakerNote image, so that the block can at
	# least be dumped to disk again in case its structure is unknown)
	$this->store_record($mknt_spc, shift @$_, $UNDEF, @$_)
	    for (['ORIGINAL'  , $mknt_offset, $mknt_size],
		 ['SIGNATURE' , \$signature],
		 ['ENDIANNESS', \$mknt_endianness],
		 ['FORMAT'    , \$format]);
	# change locally the endianness value
	local $this->{endianness} = $mknt_endianness;
	# Unstructured case: the content of the MakerNote is simply
	# a sequence of bytes, which must be decoded using $$hash{tags};
	# execute inside an eval, to confine errors inside MakerNotes
	if (exists $$hash{nonIFD}) { eval { 
	    my $p = $$hash{tags};
	    $this->store_record($mknt_dir, @$_[0,1], $data_offset, $$_[2]) 
		for map { $$p{$_} } sort { $a <=> $b } keys %$p;
	    $this->die('MakerNote size mismatch')
		unless $format =~ /unknown/ || 
		$data_offset == $mknt_offset + $mknt_size; } }
	# Structured case: the content of the MakerNote is approximately
	# a standard IFD, so parse_ifd is sufficient: it is called a se-
	# cond time if an error occurs (+ cleanup of unreliable findings),
	# but if this doesn't solve the problem, one reverts to 1st case.
	else {
	    my $args = [$mknt_dirname, $data_offset, $mknt_base, $next_flag];
	    my $code = '@$mknt_dir=@$copy; $this->parse_ifd(@$args';
	    my $copy = [@$mknt_dir]; eval "$code)";
	    $this->warn('Using predictions'), eval "$code,1)" if $@;
	    $this->warn('Predictions failed'), eval "$code)" if $@; 
	};
	# If any errors occured during the real MakerNote parsing,
	# and additional special record is saved with the error message
	# (this will be the last record in the MakerNote subdirectory)
	$this->store_record($mknt_spc, 'ERROR',$ASCII,\$@) if $@;
	# print "MESSAGE FROM MAKERNOTE:\n$@\n" if $@;
    }
}

# successful load
1;
