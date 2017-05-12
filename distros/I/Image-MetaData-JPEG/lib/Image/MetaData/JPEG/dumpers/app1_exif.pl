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
# This method dumps an Exif APP1 segment. Basically, it   #
# dumps the identifier, the two IFDs and the thumbnail.   #
###########################################################
sub dump_app1_exif {
    my ($this) = @_;
    # dump the identifier (not part of the TIFF header)
    my $identifier = $this->search_record('Identifier')->get();
    $this->set_data($identifier);
    # dump the TIFF header; note that the offset returned by
    # dump_TIFF_header is the current position in the newly written
    # data area AFTER the identifier (i.e., the base is the base
    # of the TIFF header), so it does not start from zero but from the
    # value of $ifd0_link. Be aware that its meaning is slightly
    # different from $offset in the parser.
    my ($header, $offset, $endianness) = $this->dump_TIFF_header();
    $this->set_data($header);
    # locally set the current endianness to what we have found.
    local $this->{endianness} = $endianness;
    # dump all the records of the 0th IFD, and update $offset to
    # point after the end of the current data area (with respect
    # to the TIFF header base). This must be done even if the IFD
    # itself is empty (in order to find the next one).
    my $ifd1_link = defined $this->search_record('IFD1') ? 0 : 1;
    $offset += $this->set_data($this->dump_ifd('IFD0', $offset, $ifd1_link));
    # same thing with the 1st IFD. We don't have to worry if this
    # IFD is not there, because dump_ifd tests for this case.
    $offset += $this->set_data($this->dump_ifd('IFD1', $offset, 1));
    # if there is thumbnail data in the main directory of this
    # segment, it is time to dump it. Use the reference, because
    # this can be quite large (some tens of kilobytes ....)
    if (my $th_record = $this->search_record('ThumbnailData')) {
	(undef, undef, undef, my $tdataref) = $th_record->get();
	$this->set_data($tdataref); }
}

###########################################################
# This method reconstructs a TIFF header and returns a    #
# list with all the relevant values. Nothing is written   #
# to the data area. Records are searched for in the       #
# directory specified by the second argument.             #
###########################################################
sub dump_TIFF_header {
    my ($this, $dirref) = @_;
    # retrieve the endianness, and signature. It is not worth
    # setting the temporary segment endianness here, do it later.
    my $endianness=$this->search_record('Endianness',$dirref)->get();
    my $signature =$this->search_record('Signature',$dirref)->get($endianness);
    # create a string containing the TIFF header (we always
    # choose the offset of the 0th IFD must to be 8 here).
    my $ifd0_len  = 8;
    my $ifd0_link = pack $endianness eq $BIG_ENDIAN ? "N" : "V", $ifd0_len;
    my $header = $endianness . $signature . $ifd0_link;
    # return all relevant values in a list
    return ($header, $ifd0_len, $endianness);
}

###########################################################
# This is the core of the Exif APP1 dumping method. It    #
# takes care to dump a whole IFD, including a special     #
# treatement for thumbnails and makernotes. No action is  #
# taken unless there is already a directory for this IFD  #
# in the structured data area of the segment.             #
# ------------------------------------------------------- #
# Special treatement for tags holding an IFD offset (this #
# includes makernotes); these tags are regenerated on the #
# fly (since they are no more stored) and their value is  #
# recalculated and written to the raw data area.          #
# ------------------------------------------------------- #
# New argument ($next), which specifies how the next_link #
# pointer is to be treated: '0' --> the pointer is dumped #
# with a non zero value; '1' --> the pointer is dumped    #
# with value set to zero; '2' -->: the pointer is ignored #
###########################################################
sub dump_ifd {
    my ($this, $dirnames, $offset, $next) = @_;
    # set the next link flag to zero if it is undefined
    $next = 0 unless defined $next;
    # retrieve the appropriate record list (specified by a '@' separated
    # list of dir names in $dirnames to be interpreted in sequence). If
    # this fails, return immediately with a reference to an empty string
    my $dirref = $this->search_record_value($dirnames);
    return \ (my $ns = '') unless $dirref;
    # $short and $long are two useful format strings correctly taking
    # into account the IFD endianness. $format is a format string for
    # packing an Interoperability array
    my $short   = $this->{endianness} eq $BIG_ENDIAN ? 'n' : 'v';
    my $long    = $this->{endianness} eq $BIG_ENDIAN ? 'N' : 'V';
    my $format  = $short. $short . $long;
    # retrieve the record list for this IFD, then eliminate the REFERENCE
    # records (added by the parser routine, they were not in the JPEG file).
    my @records = grep { $_->{type} != $REFERENCE } @$dirref;
    # for each reference record with a non-undef extra field, regenerate
    # the corresponding offset record (which can be retraced from the
    # "extra" field) and insert it into the @records list with a dummy
    # value (0). We can safely use $LONG as record type (new-style offsets).
    push @records, map {
	my $nt = JPEG_lookup($this->{name}, $dirnames, $_->{extra});
	new Image::MetaData::JPEG::Record($nt, $LONG, \ pack($long, 0)) }
    grep { $_->{type} == $REFERENCE && $_->{extra} } @$dirref;
    # sort the accumulated records with respect to their tags (numeric).
    # This is not, strictly speaking mandatory, but the file looks more
    # polished after this (am I introducing any gratuitous incompatibility?)
    @records = sort { $a->{key} <=> $b->{key} } @records;
    # the IFD data area is to be initialised with two bytes specifying
    # the number of Interoperability arrays.
    my $ifd_content = pack $short, scalar @records;
    # Data areas too large for the Interop array will be saved in $extra;
    # $remote should point to its beginning (from TIFF header base), so we
    # must skip 12 bytes for each Interop. array, 2 bytes for the initial
    # count (and 4 bytes for the next IFD link, unless $next is two).
    my ($remote, $extra) = ($offset + 2 + 12*@records, '');
    $remote += 4 unless $next == 2;
    # managing the thumbnail is not trivial. We want to be sure that
    # its declared size corresponds to the reality and correct if
    # this is not the case (is this a stupid idea?)
    if ($dirnames eq 'IFD1' &&
	(my $th_record = $this->search_record('ThumbnailData'))) {
	(undef, undef, undef, my $tdataref) = $th_record->get();
	for ($THTIFF_LENGTH, $THJPEG_LENGTH) {
	    my $th_len = $this->search_record($_, $dirref);
	    $th_len->set_value(length $$tdataref) if $th_len; } }
    # the following tags can be found only in IFD1 in APP1, and concern
    # the thumbnail location. They must be dealt with in a special way.
    my %th_tags = ($THTIFF_OFFSET => undef, $THJPEG_OFFSET => undef);
    # determine weather this IFD can have subidrectories or not; if so,
    # get a special mapping table from %IFD_SUBDIRS (avoid autovivification)
    my $path = join '@', $this->{name}, $dirnames;
    my $mapping = exists $IFD_SUBDIRS{$path} ? $IFD_SUBDIRS{$path} : undef;
    # loop on all selected records and dump them
    for my $record (@records) {
	# extract all necessary information about this
	# Interoperability array, with the correct endianness.
	my ($tag, $type, $count, $dataref) = $record->get($this->{endianness});
	# calculate the length of the array data, and correct $count
	# for string-like records (it had been set to 1 during the
	# parsing, it must be the data length in this case).
	my $length = length $$dataref;
	$count = $length if $record->get_category() eq 'S';
	# the last four bytes in an interoperability array are either
	# data or an address; prepare a variable for holding this value
	my $record_end = '';
	# if this IFD1 record specifies the thumbnail location, it needs
	# a special treatment, since we cannot yet know where the thumbnail
	# will be located. Write a bogus offset now and overwrite it later.
	if ($dirnames eq 'IFD1' && exists $th_tags{$tag}) {
	    $th_tags{$tag} = 8 + length $ifd_content;
	    $record_end = "\000\000\000\000"; }
	# if this Interop array is known to correspond to a subdirectory
	# (use %$mapping for this), the subdirectory content is calculated
	# on the fly, and stored in this IFD's remote data area. Its offset
	# instead is saved at the end of the Interoperability array.
	elsif ($mapping && exists $$mapping{$tag}) {
	    my $is_makernote = ($tag =~ $MAKERNOTE_TAG);
	    my $extended_dirnames = $dirnames.'@'.$$mapping{$tag};
	    # MakerNotes require a special treatment, including rewriting
	    # type and count (one LONG is really many UNDEF bytes); other
	    # subIFD's are written by a recursive dump_ifd (next link is 0).
	    my $subifd = $is_makernote ?
		$this->dump_makernote($extended_dirnames, $remote) :
		$this->dump_ifd($extended_dirnames, $remote, 1);
	    $type = $UNDEF, $count = length($$subifd) if $is_makernote;
	    $record_end = pack $long, $remote;
	    $extra .= $$subifd; $remote += length $$subifd; }
	# if the data length is not larger than four bytes, we are ok.
	# $$dataref is simply appended (with padding up to 4 bytes,
	# AFTER $$dataref, independently of the IFD endianness).
	elsif ($length <= 4) { $record_end = $$dataref . "\000"x(4-$length); }
	# if $$dataref is too big, it must be packed in the $extra
	# section, and its pointer appended here. Remember to update
	# $remote for the next record of this type.
	else { $record_end = pack $long, $remote;
	       $remote += $length; $extra .= $$dataref; }
	# the interoperability array starts with tag, type and count,
	# followed by $record_end (4 bytes): dump into the ifd data area
	$ifd_content .= (pack $format, $tag, $type, $count) . $record_end; }
    # after the Interop. arrays there can be a link to the next IFD
    # (this takes 4 bytes). $next = 0 --> write the next IFD offset,
    # = 1 --> write zero, 2 --> do not write these four bytes.
    $ifd_content .= pack $long, $remote if $next == 0;
    $ifd_content .= pack $long, 0       if $next == 1;
    # then, we save the remote data area
    $ifd_content .= $extra;
    # if the thumbnail offset tags were found during the scan, we
    # need to overwrite their values with a meaningful offset now.
    for (keys %th_tags) {
	next unless my $overwrite = $th_tags{$_};
	my $tag_record = $this->search_record($_, $dirref);
	$tag_record->set_value($remote);
	my $new_offset = $tag_record->get($this->{endianness});
	substr($ifd_content, $overwrite, length $new_offset) = $new_offset; }
    # return a reference to the scalar which holds the binary dump
    # of this IFD (to be saved in the caller routine, I think).
    return \$ifd_content;
}

###########################################################
# This routine dumps all kinds of makernotes. Have a look #
# at parse_makernote() for further details.               #
###########################################################
sub dump_makernote {
    my ($this, $dirnames, $offset) = @_;
    # look for a MakerNote subdirectory beginning with $dirnames: the
    # actual name has the format appended, e.g., MakerNoteData_Canon.
    $dirnames =~ s/(.*@|)([^@]*)/$1/;
    my $dirref = $this->search_record_value($dirnames);
    $dirnames .= $_->{key}, $dirref = $_->get_value(), last
	for (grep{$_->{key}=~/^$2/} @$dirref);
    # Also look for the subdir with special information.
    my $spcref = $this->search_record_value($dirnames.'@special');
    # entering here without the dir and its subdir being present is an error
    $this->die('MakerNote subdirs not found') unless $dirref && $spcref;
    # read all MakerNote special values (added by the parser routine)
    my ($data, $signature, $endianness, $format, $error) =
	map { $this->search_record_value($_, $spcref) }
            ('ORIGINAL', 'SIGNATURE', 'ENDIANNESS', 'FORMAT', 'ERROR');
    # die and debug if the format record is not present
    $this->die('FORMAT not found') unless $format;
    # if the format is unknown or there was an error at parse time, it
    # is wiser to return the original, unparsed content of the MakerNote
    if ($format =~ /unknown/ || defined $error) {
	$this->die('ORIGINAL data not found') unless $data; return \$data; };
    # also extract the property table for this MakerNote format
    my $hash = $$HASH_MAKERNOTES{$format};
    # now, die if the signature or endianness is still undefined
    $this->die('Properties not found')unless defined $signature && $endianness;
    # in general, the MakerNote's next-IFD link is zero, but some
    # MakerNotes do not even have these four bytes: prepare the flag
    my $next_flag = exists $$hash{nonext} ? 2 : 1;
    # in general, MakerNote's offsets are computed from the APP1 segment
    # TIFF base; however, some formats compute offsets from the beginning
    # of the MakerNote itself: setup the offset base as required.
    $offset = length($signature) + (exists $$hash{mkntstart} ? 0 : $offset);
    # initialise the data area with the detected signature
    $data = $signature;
    # some MakerNotes have a TIFF header on their own, freeing them
    # from the relocation problem; values from this header overwrite
    # the previously assigned values; records are saved in $mknt_dir.
    if (exists $$hash{mkntTIFF}) {
	my ($TIFF_header, $TIFF_offset, $TIFF_endianness) 
	    = $this->dump_TIFF_header($spcref);
	$this->die('Endianness mismatch') if $endianness ne $TIFF_endianness;
	$data .= $TIFF_header; $offset = $TIFF_offset; }
    # Unstructured case: the content of the MakerNote is simply
    # a sequence of bytes, which must be encoded using $$hash{tags}
    if (exists $$hash{nonIFD}) {
	$data .= $this->search_record($$_[0], $dirref)->get($endianness)
	    for map {$$hash{tags}{$_}} sort {$a <=> $b} keys %{$$hash{tags}}; }
    # Structured case: the content of the MakerNote can be dumped
    # with dump_ifd (change locally the endianness value).
    else { local $this->{endianness} = $endianness;
	   $data .= ${$this->dump_ifd($dirnames, $offset, $next_flag)} };
    # return the MakerNote as a binary object
    return \$data;
}

# successful load
1;
