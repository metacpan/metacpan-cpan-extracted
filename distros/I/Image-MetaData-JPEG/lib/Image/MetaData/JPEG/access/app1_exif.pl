###########################################################
# A Perl package for showing/modifying JPEG (meta)data.   #
# Copyright (C) 2004,2005,2006 Stefano Bettelli           #
# See the COPYING and LICENSE files for license terms.    #
###########################################################
package Image::MetaData::JPEG;
use Image::MetaData::JPEG::data::Tables qw(:Endianness :TagsAPP1_Exif);
use Image::MetaData::JPEG::Segment;
no  integer;
use strict;
use warnings;

###########################################################
# This method finds the $index-th Exif APP1 segment in    #
# the file, and returns its reference. If $index is       #
# undefined, it defaults to zero (i.e., first segment).   #
# If no such segment exists, it returns undef. If $index  #
# is (-1), the routine returns the number of available    #
# Exif APP1 segments (which is >= 0).                     #
###########################################################
sub retrieve_app1_Exif_segment {
    my ($this, $index) = @_;
    # prepare the segment reference to be returned
    my $chosen_segment = undef;
    # $index defaults to zero if undefined
    $index = 0 unless defined $index;
    # get the references of all APP1 segments
    my @references = $this->get_segments('APP1$');
    # filter out those without Exif information
    @references = grep { $_->is_app1_Exif() } @references;
    # if $index is -1, return the size of @references
    return scalar @references if $index == -1;
    # return the $index-th such segment, or undef if absent
    return exists $references[$index] ? $references[$index] : undef;
}

###########################################################
# This method forces an Exif APP1 segment to be present   #
# in the file, and returns its reference. The algorithm   #
# is the following: 1) if at least one segment with these #
# properties is already present, the first one is retur-  #
# ned; 2) if [1] fails, an APP1 segment is added and      #
# initialised with an Exif structure.                     #
###########################################################
sub provide_app1_Exif_segment {
    my ($this) = @_;
    # get the references of all APP1 segments
    my @app1_refs = $this->get_segments('APP1$');
    # filter out those without Exif information
    my @Exif_refs = grep { $_->is_app1_Exif() } @app1_refs;
    # if @Exif_refs is not empty, return the first segment
    return $Exif_refs[0] if @Exif_refs;
    # if we are still here, an Exif APP1 segment must be created
    # and initialised (contrary to the IPTC case, an existing APP1
    # segment, presumably XPM, cannot be "adapted"). We write here
    # a minimal Exif segment with no data at all (in big endian).
    my $minimal_exif = $APP1_EXIF_TAG . $BIG_ENDIAN
	. pack "nNnN", $APP1_TIFF_SIG, 8, 0, 0;
    my $Exif = new Image::MetaData::JPEG::Segment('APP1', \ $minimal_exif);
    # choose a position for the new segment (the improved version
    # of find_new_app_segment_position can now be safely used).
    my $position = $this->find_new_app_segment_position('APP1');
    # actually insert the segment
    $this->insert_segments($Exif, $position);
    # return a reference to the new segment
    return $Exif;
}

###########################################################
# This method eliminates the $index-th Exif APP1 segment  #
# from the JPEG file segment list. If $index is (-1) or   #
# undef, all Exif APP1 segments are affected at once.     #
###########################################################
sub remove_app1_Exif_info {
    my ($this, $index) = @_;
    # the default value for $index is -1
    $index = -1 unless defined $index;
    # this is the list of segments to be purged (initially empty)
    my %deleteme = ();
    # call the selection routine and save the segment reference
    my $segment = $this->retrieve_app1_Exif_segment($index);
    # if $segment is really a non-null segment reference, mark it
    # for deletion; otherwise, it is the number of segments to be
    # deleted (this happens if $index is -1). In this case, the
    # whole procedure is repeated for every index.
    $segment->{name} = "deleteme" if ref $segment;
    if ($index == -1) { $this->retrieve_app1_Exif_segment($_)
			    ->{name} = "deleteme" for 0..($segment-1); }
    # remove marked segments from the file
    $this->drop_segments('deleteme');
}

###########################################################
# This method is an interface to the method with the same #
# name in the Segment class. First, the first Exif APP1   #
# segment is retrieved (if there is no such segment, the  #
# undefined value is returned). Then the get_Exif_data is #
# called on this segment passing the arguments through.   #
# For further details, see Segment::get_Exif_data() and   #
# JPEG::retrieve_app1_Exif_segment().                     #
###########################################################
sub get_Exif_data {
    my $this = shift;
    # get the first Exif APP1 segment in the current JPEG
    # file (if no such segment exists, this returns undef).
    my $segment = $this->retrieve_app1_Exif_segment();
    # return undef if not suitable segment exists
    return undef unless defined $segment;
    # pass the arguments through to the Segment method
    return $segment->get_Exif_data(@_);
}

###########################################################
# This method is an interface to the method with the same #
# name in the Segment class. First, the first Exif APP1   #
# segment is retrieved (if there is no such segment, one  #
# is created and initialised). Then the set_Exif_data is  #
# called on this segment passing the arguments through.   #
# For further details, see Segment::set_Exif_data() and   #
# JPEG::provide_app1_Exif_segment().                      #
###########################################################
sub set_Exif_data {
    my $this = shift;
    # get the first Exif APP1 segment in the current JPEG file
    # (if there is no such segment, initialise one; therefore,
    # this call cannot fail [mhh ...]).
    my $segment = $this->provide_app1_Exif_segment();
    # pass the arguments through to the Segment method
    return $segment->set_Exif_data(@_);
}

###########################################################
# An Interoperability subIFD is supposed to be used for,  #
# well, inter-operability, so it should be made as stan-  #
# dard as possible. This method takes care to chose a set #
# of "correct" values for you: the Index is set to "R98"  #
# (because we are interested in IFD0), Version to 1.0,    #
# FileFormat to Exif v.2.2, and the picture dimensions    #
# are taken from get_dimensions().                        #
###########################################################
sub forge_interoperability_IFD {
    my $this = shift;
    # get the real picture dimensions
    my ($x_dim, $y_dim) = $this->get_dimensions();
    # prepare a table of records for the Interop. IFD
    my $std_values = {
	'InteroperabilityIndex'   => "R98",
	'InteroperabilityVersion' => "0100",
	'RelatedImageFileFormat', => "Exif JPEG Ver. 2.2",
	'RelatedImageWidth'       => $x_dim,
	'RelatedImageLength'      => $y_dim, };
    # call the setter method for Exif data appropriately
    return $this->set_Exif_data($std_values, 'INTEROP_DATA', 'REPLACE');
}

###########################################################
# The following routines best fit as Segment methods.     #
###########################################################
package Image::MetaData::JPEG::Segment;
use Image::MetaData::JPEG::data::Tables qw(:Lookups);

###########################################################
# A private hash for get_Exif_data and set_Exif_data.     #
# Each '@' indicates the beginning of a new subdirectory. #
###########################################################
my %WHAT2IFD = ('ROOT_DATA'      => '',
		'IFD0_DATA'      => '@IFD0',
		'SUBIFD_DATA'    => '@IFD0@SubIFD',
		'GPS_DATA'       => '@IFD0@GPS',
		'INTEROP_DATA'   => '@IFD0@SubIFD@Interop',
		'MAKERNOTE_DATA' => '@IFD0@SubIFD@MakerNoteData',
		'IFD1_DATA'      => '@IFD1' );

###########################################################
# This method inspects a segments, and returns "undef" if #
# it is not an APP1 segment or if its structure is not    #
# Exif like. Otherwise, it returns "ok".                  #
###########################################################
sub is_app1_Exif {
    my ($this) = @_;
    # return undef if this segment is not APP1
    return undef unless $this->{name} eq 'APP1';
    # return undef if there is no 'Identifier' in this segment 
    # or if it does not match with an Exif-like segment
    my $identifier = $this->search_record_value('Identifier');
    return undef unless defined $identifier && $identifier eq $APP1_EXIF_TAG;
    # return ok
    return "ok";
}

###########################################################
# This method accepts two arguments ($what and $type) and #
# returns the content of the Exif APP1 segment packed in  #
# various forms. All Exif records are natively identified #
# by numeric tags (keys), which can be "translated" into  #
# a human-readable form by using the Exif standard docs;  #
# only a few fields in the Exif APP1 preamble (they are   #
# not Exif records) are always identified by this module  #
# by means of textual tags. The $type argument selects    #
# the output format for the record keys (tags):           #
#  - NUMERIC: record tags are native numeric keys         #
#  - TEXTUAL: record tags are human-readable (default)    #
# Of course, record values are never translated. If a     #
# numeric Exif tag is not known, a custom textual key is  #
# created with "Unknown_tag_" followed by the numerical   #
# value (this solves problems with non-standard tags).    #
# ------------------------------------------------------- #
# Error conditions (invalid $what's and $type's) manifest #
# themselves through an undefined return value. So, undef #
# should not be used for other cases: use empty hashes or #
# a reference to an empty string for the thumbnail.       #
# ------------------------------------------------------- #
# The subset of Exif tags returned by this method is      #
# determined by the value of $what. If $what is set equal #
# to '*_DATA', this method returns a reference to a flat  #
# hash, corresponding to one or more IFD (sub)dirs:       #
#  - ROOT_DATA      APP1(TIFF header records and similar) #
#  - IFD0_DATA      APP1@IFD0   (primary image TIFF tags) #
#  - SUBIFD_DATA    APP1@IFD0@SubIFD (Exif private tags)  #
#  - GPS_DATA       APP1@IFD0@GPS    (GPS data in IFD0)   #
#  - INTEROP_DATA   APP1@IFD0@SubIFD@Interop(erability)   #  
#  - IFD1_DATA      APP1@IFD1   (thumbnail TIFF tags)     #
#  - IMAGE_DATA     a merge of IFD0_DATA and SUBIFD_DATA  #
#  - THUMB_DATA     an alias for IFD1_DATA                #
# Setting $what equal to 'ALL' returns a data dump very   #
# close to the Exif APP1 segment structure; the returned  #
# value is a reference to a hash of hashes: each element  #
# of the root-level hash is a pair ($name, $hashref),     #
# where $hashref points to a second-level hash containing #
# a copy of all Exif records present in the $name IFD     #
# (sub)directory. The root-level hash includes a special  #
# root directory (named 'APP1') containing some non Exif  #
# parameters. Last, setting $what to 'THUMBNAIL' returns  #
# a reference to a copy of the actual Exif thumbnail      #
# image (not returned by 'THUMB_DATA'), if present, or a  #
# reference to an empty string, if not present.           #
# ------------------------------------------------------- #
# Note that the Exif record values' format is not checked #
# to be valid according to the Exif standard. This is, in #
# some sense, consistent with the fact that also "unknown"#
# tags are included in the output.                        #
###########################################################
sub get_Exif_data {
    my ($this, $what, $type) = @_;
    # refuse to work unless you are an Exif APP1 segment
    return undef unless $this->is_app1_Exif();
    # set the default section and type, if undefined;
    $what = 'ALL'       unless defined $what;
    $type = 'TEXTUAL'   unless defined $type;
    # reject unknown types (return undef, which means 'error')
    return undef unless $type =~ /^NUMERIC$|^TEXTUAL$/;
    # a reference to the hash to be returned, initially empty
    my $pairs = {};
    # ========= SPECIAL CASES ====================================
    # IMAGE_DATA means IFD0_DATA and SUBIFD_DATA (merged)
    if ($what eq 'IMAGE_DATA') {
	for ('IFD0_DATA', 'SUBIFD_DATA') {
	    my $h = $this->get_Exif_data($_, $type);
	    @$pairs{keys %$h} = values %$h; } return $pairs; }
    # ALL means a hash of hashes with all subdirs (even if emtpy)
    if ($what eq 'ALL') {
	$$pairs{$_} = $this->get_Exif_data($_, $type) for keys %WHAT2IFD;
	return $pairs; }
    # $what equal to 'THUMBNAIL' is special: it returns a copy of the
    # thumbnail data area (this can be a self-contained JPEG picture
    # or an uncompressed picture needing more parameters from IFD1).
    # If no thumbnail is there, return a reference to an empty string
    if ($what eq 'THUMBNAIL') {
	my $thumbnail = $this->search_record_value('ThumbnailData');
	return $thumbnail ? \ $thumbnail : \ (my $ns = ''); }
    # IFD1_DATA is an alias for THUMB_DATA
    $what = 'IFD1_DATA' if $what eq 'THUMB_DATA';
    # ============================================================
    # %WHAT2IFD keys must correspond to the legal $what's. It is now
    # time to reject unknown sections ('THUMBNAIL' already dealt with).
    # As usual, this error condition corresponds to returning undef.
    return undef unless exists $WHAT2IFD{$what};
    # $WHAT2IFD{$what} contains a '@' separated list of dir names;
    # use it to retrieve a reference to the appropriate record list
    my $path = $WHAT2IFD{$what};
    # follow the path blindly, get undef on problems
    my $dirref = $this->search_record_value($path);
    # give $path a second try, assuming the last part of the path
    # is just the beginning of a tag (this is needed for MakerNote).
    # This might modify $path and set $dirref to non-undefined.
    unless (defined $dirref) {
	$path =~ s/(.*@|)([^@]*)/$1/;
	my $partial_dirref = $this->search_record_value($path);
	$path .= $_->{key}, $dirref = $_->get_value(), last
	    for (grep{$_->{key}=~/^$2/} @$partial_dirref);}
    # if $dirref is undefined, the corresponding subdirectory was not
    # present, and we are going to return a reference to an empty hash
    return $pairs unless $dirref;
    # map the record list reference to a full hash containing the subdir-
    # ectory records as (tag => values) pairs. Do not include $REFERENCE's
    # (private). Make COPIES of the array references found in $_->{values}
    # (the caller could use them to corrupt the internal structures).
    %$pairs = map  { $_->{key} => [ @{$_->{values}} ] }
              grep { $_->{type} != $REFERENCE } @$dirref;
    # up to now, all record keys (tags) are numeric (exception made for
    # some MakerNote keys and all keys in the "root" directory, for which
    # there is no numeric counterpart). If $type is 'TEXTUAL', they must
    # be translated (test explicitely that they are numeric).
    if ($type eq "TEXTUAL") {
	# get the right numeric-to-textual conversion table with $path
	my $table = JPEG_lookup($this->{name}, $path);
	# run the translation (create a name also for unknown tags)
	%$pairs = map { (($_!~/^\d+$/)?$_:(exists $$table{$_}) ? $$table{$_} :
			 "Unknown_tag_$_") => $$pairs{$_} } keys %$pairs; }
    # return the reference to the hash containing all data
    return $pairs;
}

###########################################################
# This method is the entry point for setting Exif data in #
# the current APP1 segment. The mandatory arguments are:  #
# $data (hash reference, with new records to be written), #
# $what (a scalar, selecting the concerned portion of the #
# Exif APP1 segment) and $action (a scalar specifying the #
# requested action). Valid values are:                    #
#   $action --> ADD | REPLACE                             #
#   $what --> IFD0_DATA, IFD1_DATA, INTEROP_DATA,         #
#             GPS_DATA, SUBIFD_DATA (see get_Exif_data)   #
#             THUMB_DATA (an alias for IFD1_DATA)         #
#             IMAGE_DATA (IFD0_DATA or SUBIFD_DATA)       #
#             ROOT_DATA  (only 'Endianness' can be set)   #
#          .- THUMBNAIL  (including automatic fields)     #
#          \____.--> $data is a scalar reference here ... #
# The behaviour of $action is similar to that for IPTC    #
# data. Note that Exif records are non-repeatable in      #
# nature, so there is no need for an 'UPDATE' action in   #
# addition to 'ADD' (they would both overwrite an old re- #
# cord with the same tag as a new record); $action equal  #
# to 'REPLACE', on the other hand, clears the appropriate #
# record list(s) before the insertions. Records are       #
# rewritten in increasing (numerical) tag order.          #
# The elements of $data which can be converted to valid   #
# records are inserted in the appropriate (sub)IFD, the   #
# others are returned. The return value is always a hash  #
# reference; in general it contains rejected records. If  #
# an error occurs in a very early stage of the setter,    #
# this reference contains a single entry with key='ERROR' #
# and value set to some meaningful error message. So, a   #
# reference to an empty hash means that everything was OK.#
# ------------------------------------------------------- #
# $what equal to 'THUMBNAIL' is meant to replace the IFD1 #
# thumbnail. $data should be a reference to a scalar or   #
# to a JPEG object containing the new thumbnail ; if it   #
# points to an emtpy string, the thumbnail is erased.     #
# Corresponding fields follow the thumbnail (all this is  #
# dealt with by a private method). $data undefined DOES   #
# NOT erase the thumbnail, it is an error (too dangerous).#
# ------------------------------------------------------- #
# When $what is 'IMAGE_DATA', try to insert first into    #
# SubIFD, then, into IFD0. This favours SubIFD standard   #
# tags in front of IFD company-related non-standard tags. #
# For security reasons however, these non-standard tags   #
# should be labelled as invalid: this would prevent them  #
# from being set but not from being recognised if present.#
# ------------------------------------------------------- #
# Remeber that, even for $action eq REPLACE, we cannot    #
# delete all the records. We must preserve $REFERENCE     #
# records, otherwise the corresponding directories would  #
# be forgotten; we don't want that, for instance, SubIFD  #
# is deleted when the records of IFD0 are REPLACED.       #
# ------------------------------------------------------- #
# The fourth argument ($dontupdate) is to be considered   #
# strictly private. It is used by set_Exif_data itself    #
# when called with $action eq 'IMAGE_DATA', so that the   #
# update() routine can be called only once (not twice).   #
# ------------------------------------------------------- #
# First, some basic argument checking is performed: the   #
# segment must be of the appropriate type, $data must be  #
# a hash reference, $action and $what must be valid.      #
# Then, the appropriate record (sub)directory is created  #
# (this can trigger the creation of other directories),   #
# if it is not present. Then records are screened and     #
# set. Mandatory data are added, if not present, at the   #
# end of the process (see Tables.pm for this). Note that  #
# there are some record intercorrelations still neglected.#
###########################################################
sub set_Exif_data {
    my ($this, $data, $what, $action, $dontupdate) = @_;
    # refuse to work unless you are an Exif APP1 segment
    return {'ERROR'=>'Not an Exif APP1 segment'} unless $this->is_app1_Exif();
    # set the default action, if undefined
    $action = 'REPLACE' unless defined $action;
    # refuse to work for unkwnon actions
    return {'ERROR'=>"Unknown action $action"} unless $action =~ /ADD|REPLACE/;
    # return immediately if $data is undefined
    return {'ERROR'=>'Undefined data reference'} unless defined $data;
    # ========= SPECIAL CASES ====================================
    # IMAGE_DATA: first, try to insert all tags into SubIFD, then, try
    # to insert rejected data into IFD0, last, return doubly rejected data.
    if ($what eq 'IMAGE_DATA') {
	my $rejected = $this->set_Exif_data($data, 'SUBIFD_DATA', $action, 1);
	return $this->set_Exif_data($rejected, 'IFD0_DATA', $action); }
    # THUMBNAIL requires a very specific treatment
    return $this->set_Exif_thumbnail($data) if $what eq 'THUMBNAIL';
    # 'THUMB_DATA' is an alias to 'IFD1_DATA'
    $what = 'IFD1_DATA' if $what eq 'THUMB_DATA';
    # ============================================================
    # $data must be a hash reference (from this point on)
    return {'ERROR'=>'$data not a hash reference'} unless ref $data eq 'HASH';
    # return with an error if $what is not a valid key in %WHAT2IFD
    return {'ERROR'=>"Unknown section $what"} unless exists $WHAT2IFD{$what};
    # translate $what into a path specification
    my $path = 'APP1' . $WHAT2IFD{$what};
    # the mandatory records list must be present (debug point)
    return {'ERROR'=>'no $mandatory records'} unless exists
	$IFD_SUBDIRS{$path}{'__mandatory'};
    # get the mandatory record list
    my $mandatory = $IFD_SUBDIRS{$path}{'__mandatory'};
    # all arguments look healty, go to stage two; get the record list
    # of the appropriate (sub)directory; this call creates the supporting
    # directory tree if necessary, taking care of gory details.
    my $record_list = $this->build_IFD_directory_tree($path);
    # analyse the passed records for correctness (syntactical rules);
    # the following function divides them into two obvious categories
    my ($rejected, $accepted) = $this->screen_records($data, $path);
    # For $action equal to 'ADD', we read the old records and insert
    # them in the $accepted hash, unless they are already present.
    # If $action is 'REPLACE' we preserve only the subdirectories
    my $save = $action eq 'REPLACE' ? 'p' : '.';
    my $old_records = [ grep {$_->get_category() =~ $save} @$record_list ];
    $this->complement_records($old_records, $accepted);
    # retrieve the section about mandatory values for this $path and transform
    # them into Records (there is also a syntactical analysis, but all records
    # should be accepted here, so I take the return value in scalar context).
    # ('B' is currently necessary for stupid root-level mandatory records)
    my ($notempty, $values) = $this->screen_records($mandatory, $path, 'B');
    $this->die('Mandatory values rejected') if %$notempty;
    # merge in mandatory records, if they are not already present
    $this->complement_records($values, $accepted);
    # take all records from $accepted and set them into the record
    # list (their order must anambiguous, so perform a clever sorting).
    @$record_list = ordered_record_list($accepted, $path);
    # commit changes to the data area unless explicitely forbidden
    $this->update() unless $dontupdate;
    # that's it, return the reference to the rejected data hash
    return $rejected;
}

###########################################################
# This private method is called by set_Exif_data when the #
# $what argument is set to 'THUMBNAIL'. $data must be a   #
# reference to a JPEG object or a reference to a scalar   #
# value containing a valid JPEG stream (an undefined ref. #
# is considered an error!). First, we erase all thumbnail #
# related records from IFD1 then we reinsert those which  #
# are appropriate. Last, the update method is called      #
# (this also fixes some fields).                          #
# ------------------------------------------------------- #
# ($$data is ''): nothing else to do, thumbnail erased.   #
# ($$data is a JPEG stream or a JPEG object): thumbnail   #
#   data are saved in the root level directory, and a few #
#   records are added to IFD1: 'JPEGInterchangeFormat',   #
#   'JPEGInterchangeFormatLength', and 'Compression' set  #
#    to six (this indicates a JPEG thumbnail).            #
###########################################################
sub set_Exif_thumbnail {
    my ($this, $dataref) = @_;
    # this variable holds the thumbnail format
    my $type = undef;
    # $dataref must be a valid reference: I don't want the user to be
    # able to erase the thumbnail by passing an erroneously undef ref.
    return { 'ERROR' => 'argument is not a reference' } unless ref $dataref;
    # if $dataref points to an Image::MetaData::JPEG object, replace it
    # with a reference to its bare content and set $type to 'JPEG'.
    if ('Image::MetaData::JPEG' eq ref $dataref) {
	my $r = ""; $dataref->save(\ $r); $dataref = \ $r; $type = 'JPEG'; }
    # $dataref must now be a scalar reference; everything else is an error
    return { 'ERROR' => 'not a good reference' } if ref $dataref ne 'SCALAR';
    # try to recognise the content of $$dataref. If it is defined but empty,
    # we just need to erase the thumbnail. If it is accepted by the JPEG
    # ctor or $type is already 'JPEG', we consider it a regular JPEG stream.
    $type = 'NONE' if length $$dataref == 0;
    $type = 'JPEG' if ! $type && Image::MetaData::JPEG->new($dataref, '');
    # If $type is not yet set, generate an error (TIFF not yet supported ...)
    return { 'Error' => 'unsupported thumbnail format' } unless $type;
    # the following lists contain all records to be erased before inserting
    # the new thumbnail. They are inserted in a hash for faster lookup
    my %thumb_records = map { $_ => 1 } 
    ('Compression', 'JPEGInterchangeFormat', 'JPEGInterchangeFormatLength',
     'StripOffsets','ImageWidth','ImageLength','BitsPerSample',
     'SamplesPerPixel', 'RowsPerStrip', 'StripByteCounts');
    # get the appropriate record lists (IFD1) (build it if not present)
    my $ifd1_list = $this->build_IFD_directory_tree('APP1@IFD1');    
    # delete all tags mentioned in %forbidden. This is a fresh start before
    # inserting a new thumbnail (and the whole story if $type is 'NONE')
    @$ifd1_list = grep 
    {! exists $thumb_records{JPEG_lookup('APP1@IFD1', $_->{key})}} @$ifd1_list;
    # delete existing thumbnail data and replace it if necessary; this
    # "record" is in the root directory, and a regular expression check
    # is really impossible. So, we adopt a low-level approach here ...
    my $root_list = $this->{records};
    @$root_list = grep { $_->{key} ne 'ThumbnailData' } @$root_list;
    # insert the thumbnail, if necessary (this must be the last record)
    push @$root_list, new Image::MetaData::JPEG::Record
	('ThumbnailData', $UNDEF, $dataref, length $$dataref) if $dataref;
    # if $type is 'JPEG', we need to insert some records in IFD1 ...
    if ($type eq 'JPEG') {
	# we have two non-offset records: the thumbnail type and its length
	my $records = { 'Compression' => 6, # 6 means JPEG-compressed
			'JPEGInterchangeFormatLength' => length $$dataref };
	# analyse the passed records for correctness (semi-paranoia)
	my ($rej, $accepted) = $this->screen_records($records,'APP1@IFD1','T');
	# $rej must be an empty hash, or we have a problem
	return { 'Error' => 'Records rejected internally! [JPEG]' } if %$rej;
	# add all other old (non-thumbnail-related) records
	$this->complement_records($ifd1_list, $accepted);
	# add the 'JPEGInterchangeFormat' record (an offset). This is really
	# dummy, it is here to trigger the correct behaviour in update(), but
	# I really should modify update() to make it calculate the field on
	# its own (since it already calcuates its value anyway).
	my $JIF = JPEG_lookup('APP1@IFD1', 'JPEGInterchangeFormat');
	$$accepted{$JIF} = new 
	    Image::MetaData::JPEG::Record($JIF, $LONG, \ ("\000" x 4), 1);
	# take all records from $accepted and set them into the record
	# list (their order must anambiguous, so perform a clever sorting).
	@$ifd1_list = ordered_record_list($accepted, 'APP1@IFD1'); }
    # remember to commit these changes to the data area
    $this->update();
    # return success (a reference to an empty hash)
    return {};
}

###########################################################
# This helper function returns an ordered list of records.#
# Records are sorted according to the numerical value of  #
# their key; if the key is not numeric, but its transla-  #
# tion matches Idx-n, n is used. If even this fails, a    #
# stringwise comparison is performed ($REFERENCE records).#
###########################################################
sub ordered_record_list {
    my ($data, $path) = @_;
    # a regular expression for an integer positive number
    my $num = qr/^\d+$/o;
    # tag to number translation; if the tag is not numeric and translates
    # to Idx-n, return n. If even this fails, return the textual tag itself
    # (the last case should be restricted to subdirectory entries).
    my $tag_index = sub { return $_[0] if $_[0] =~ /$num/;
			  my $n = JPEG_lookup($path, $_[0]);
			  $n =~ s/^Idx-(\d+)$/$1/; $n =~ /$num/ ? $n : $_[0] };
    # numeric comparison when possible, stringwise comparison otherwise
    my $comp = sub { (grep {!/$num/} @_) ? $_[0] cmp $_[1] : $_[0] <=> $_[1] };
    # the actual sorting function for the sort operator
    my $or = sub { &$comp(&$tag_index($a), &$tag_index($b)) };
    # take all records from $data and perform a sorting
    map {$$data{$_}} sort {&$or} keys %$data;
}

###########################################################
# This method, obviously, creates a (sub)directory tree   #
# in an IFD-like segment (i.e. APP1/APP3). The argument   #
# is a string describing the tree, like 'APP1@IFD0@GPS'.  #
# This method takes care of the "extra" field of the      #
# newly created directories if mandatory or useful. The   #
# return value is the record list of the deepest subdir.  #
###########################################################
sub build_IFD_directory_tree {
    my ($this, $dirnames) = @_;
    # split the passed string into tokens on '@'
    my ($first, @dirnames) = split '@', $dirnames;
    # the first token must correspond to the segment name
    $this->die("Incorrect segment ($first)") unless $first eq $this->{name};
    # build the whole directory tree, as requested
    $this->provide_subdirectory(@dirnames);
    # prepare two "running" variables
    my $dirref = $this->{records};
    my $path = $first;
    # travel through the token list and fix the tree
    for my $name (@dirnames) {
	# get the $REFERENCE record for the subdir $name
	my $record = $this->search_record($name, $dirref);
	# if there is information in %IFD_SUBDIR ...
	if (exists $IFD_SUBDIRS{$path}) {
	    # get the reverse (offset tag => subdir name) mapping
	    my %revmapping = reverse %{$IFD_SUBDIRS{$path}};
	    # if $name is present in %revmapping, set the "extra" field
	    # of $record. This used to be necessary during the dump stage;
	    # now, it could be avoided by using %IFD_SUBDIRS, but displaying
	    # this kind of information is nonetheless usefull.
	    $record->{extra} = JPEG_lookup($path, $revmapping{$name})
		if exists $revmapping{$name}; }
	# update the running variables
	$dirref = $record->get_value();
	$path = join '@', $path, $name; }
    # return the final value of $dirref
    return $dirref;
}

###########################################################
# This private method takes a reference to a Record list  #
# or hash and a reference to a Record hash, and inserts   #
# all records from the first container into the hash,     #
# unless its key is already present.                      #
###########################################################
sub complement_records {
    my ($this, $record_container, $record_hash) = @_;
    # be sure that the first argument is not a scalar
    $this->die('first arg. not a reference') unless ref $record_container;
    # get a record list from the record container
    my $record_list = (ref $record_container eq 'HASH') ?
	[ values %$record_container ] : $record_container;
    # records from a list
    for (@$record_list) {
	$$record_hash{$_->{key}} = $_ 
	    unless exists $$record_hash{$_->{key}}; }
}

###########################################################
# This method takes a hash reference [$data] and an IFD   #
# path specification [$path] (like 'APP1@IFD0@GPS'). It   #
# then tries to convert the elements of $data into valid  #
# records according to the specific syntactical rules of  #
# the corresponding IFD. It returns a list of two hash    #
# references: the first list contains the key-recordref   #
# pairs for successful conversions, the other one the     #
# key-value(ref) pairs for unsuccessful ones.             #
#---------------------------------------------------------#
# Records' tags can be give textually or numerically.     #
# First, the tags are checked for validity and converted  #
# to numeric form (records with undefined values are      #
# immediately rejected). Then, the specifications for     #
# each tag are read from a helper table and values are    #
# matched against a regular expression (or a surrogate,   #
# see %special_screen_rules). Then a Record object is     #
# forged and evaluated to see if it is valid and it       #
# corresponds to the user will.                           #
#---------------------------------------------------------#
# New feature: if the record value is a code reference    #
# instead of an array reference, the corresponding code   #
# is executed (passing the segment reference through) and #
# the result is stored. This is necessary for mandatory   #
# records which need to know the current segment.         #
#---------------------------------------------------------#
# New feature. The syntax hash can have a fifth field,    #
# acting as a filter. Unless it matches the optional      #
# $fregex argument, the record is rejected. This allows   #
# us to exclude some tags from general usage. If $fregex  #
# is undefined, all tags with a filter are rejected.      #
###########################################################
sub screen_records {
    my ($this, $data, $path, $fregex) = @_;
    # prepare two hashes for rejected and accepted records
    my $rejected = {}; my $accepted = {};
    # die immediately if $data or $path are not defined
    $this->die('Undefined arguments') unless defined $data && defined $path;
    # get a reference to the hash with all record properties
    $this->die('Supporting hash not found') unless exists $IFD_SUBDIRS{$path};
    my $syntax = $IFD_SUBDIRS{$path}{'__syntax'};
    $this->die('Syntax specification not found') unless $syntax;
    # loop over entries in $data and decide whether to accept them or not
    while (my ($key, $value) = each %$data) {
	# do a key lookup and save the result
	my $key_lookup = JPEG_lookup($path, $key);
	# use the looked-up key if it is numeric
	$key = $key_lookup if defined $key_lookup && $key_lookup =~ /^\d+$/;
	# I have never been optimist ...
	$$rejected{$key} = $value;
	# reject unknown keys
	next unless defined $key_lookup;
	# of course, check that $value is defined
	next unless defined $value;
	# if value is a code reference, execute it, passing $this
	$value = &$value($this) if ref $value eq 'CODE';
	# if value is a scalar, transform it into a single-valued array
	$value = [ $value ] unless ref $value;
	# $value must now be an array reference
	next unless ref $value eq 'ARRAY';
	# get all mandatory properties of this record
	my ($name, $type, $count, $rule, $filter) = @{$$syntax{$key}};
	# a "rule" matching 'calculated' means that this record
	# cannot be supplied by the user (so, we reject it)
	next if $rule =~ /calculated/;
	# very special mechanism to inhibit some tags
	next if defined $filter && ((!defined $fregex)||($filter!~/$fregex/));
	# if $type is $ASCII and $$value[0] is not null terminated,
	# we are going to add the null character for the lazy user
	$$value[0].="\000" if $type==$ASCII && @$value && $$value[0]!~/\000$/;
	# if $rule points to an anonymous subroutine (i.e., a special rule,
	# execute the corresponding code and reject if it fails (i.e. dies);
	# otherwise, $rule must be interpreted as a regular expression (if
	# the record is multi-valued, $rule must match all the elements).
	if (ref $rule eq 'CODE') { eval { &$rule(@$value) }; next if $@; }
	else { next unless scalar @$value == grep {$_ =~ /^$rule$/s} @$value; }
	# let us see if the values can actually be saved
	# in a record ($record remains undef on failure). 
	next unless my $record = 
	    Image::MetaData::JPEG::Record->check_consistency
	    ($key, $type, $count, $value);
	# well, it seems that the record is OK, so my pessimism
	# was not justified. Let us change the record status
	delete $$rejected{$key};
	$$accepted{$key} = $record;
    }
    # return references to accepted and rejected data
    return ($rejected, $accepted);
}

# successful package load
1;
