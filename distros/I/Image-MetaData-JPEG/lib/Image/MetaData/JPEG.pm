###########################################################
# A Perl package for showing/modifying JPEG (meta)data.   #
# Copyright (C) 2004,2005,2006 Stefano Bettelli           #
# See the COPYING and LICENSE files for license terms.    #
###########################################################
#use 5.008;
package Image::MetaData::JPEG;
use Image::MetaData::JPEG::data::Tables qw(:JPEGgrammar);
use Image::MetaData::JPEG::Backtrace;
use Image::MetaData::JPEG::Segment;
no  integer;
use strict;
use warnings;

our $VERSION = '0.159';

###########################################################
# These simple methods should be used instead of standard #
# "warn" and "die" in this package; they print a much     #
# more elaborated error message (including a stack trace).#
# Warnings can be turned off altogether simply by setting # 
# Image::MetaData::JPEG::show_warnings to false.          #
###########################################################
sub warn { my ($this, $message) = @_;
	   warn Image::MetaData::JPEG::Backtrace::backtrace
	       ($message, "Warning" . $this->info(), $this)
	       if $Image::MetaData::JPEG::show_warnings; }
sub die  { my ($this, $message) = @_;
	   die Image::MetaData::JPEG::Backtrace::backtrace
	       ($message, "Fatal error" . $this->info(), $this); }
sub info { my ($this) = @_;
	   my $filename = $this->{filename} || '<no file name>';
	   return " [file $filename]"; }

###########################################################
# Constructor for a JPEG file structure object, accepting #
# a "JPEG stream". It parses the file stream and stores   #
# its sections internally. An optional parameter can ex-  #
# clude parsing and even storing for some segments. The   #
# stream can be specified in two ways:                    #
# - [a scalar] interpreted as a file name to be opened;   #
# - [a scalar reference] interpreted as a pointer to an   #
#   in-memory buffer containing a JPEG stream;            #
# ------------------------------------------------------- #
# There is now a second argument, $regex. This string is  #
# matched against segment names, and only those segments  #
# with a positive match are parsed. This allows for some  #
# speed-up if you just need partial information. For      #
# instance, if you just want to manipulate the comments,  #
# you could use $regex equal to 'COM'. If $regex is unde- #
# fined, all segments are matched.                        #
# ------------------------------------------------------- #
# There is now a third optional argument, $options. If it #
# matches the string 'FASTREADONLY', only those segments  #
# matching $regex are actually stored; also, everything   #
# which is found after a Start Of Scan is completely      #
# neglected. This allows for very large speed-ups, but,   #
# obviously, you cannot rebuild the file afterwards, so   #
# this is only for getting information fast (e.g., when   #
# doing a directory scan).                                #
# ------------------------------------------------------- #
# If an unrecoverable error occurs during the execution   #
# of the constructor, the undefined value is returned     #
# instead of the object reference, and a meaningful error #
# message is set up (read it with Error()).               #
###########################################################
sub new {
    my ($pkg, $file_input, $regex, $options) = @_;
    my $this = bless {
	filename      => undef, # private
	handle        => undef, # private
	read_only     => undef, # private
	segments      => [],
    }, $pkg;
    # remember to unset the ctor error message 
    $pkg->SetError(undef);
    # set the read-only flag if $options matches FASTREADONLY
    $this->{read_only} = $options =~ m/FASTREADONLY/ if $options;
    # execute the following subroutines in an eval block so that
    # errors can be treated without shutting down the caller.
    my $status = eval { $this->open_input($file_input); 
			$this->parse_segments($regex) ; };
    # close the file handle, if open
    $this->close_input();
    # If an error was found (and it triggered a die call)
    # we must set the appropriate error variable here
    $pkg->SetError($@) unless $status;
    # return the object reference (undef if an error occurred)
    return $this->Error() ? undef : $this;
}

###########################################################
# This block declares a private variable containing a     #
# meaningful error message for problems during the class  #
# constructor. The two following methods allow reading    #
# and setting the value of this variable.                 #
###########################################################
{ my $ctor_error_message = undef;
  sub Error    { return $ctor_error_message || undef; }
  sub SetError { $ctor_error_message = $_[1]; }
}

###########################################################
# This method writes the data area of each segment in the #
# current object to a disk file or a variable in memory.  #
# A disk file is written if $filename is a scalar with a  #
# valid file name; memory is instead used if $filename is #
# a scalar reference. If $filename is undef, it defaults  #
# to the file originally used to create the current JPEG  #
# structure object. This method returns "true" (1) if it  #
# works, "false" (undef) otherwise. This call fails if    #
# the "read_only" member is set.                          #
# ------------------------------------------------------- #
# Remember that if you make changes to any segment, you   #
# should call update() for that particular segment before #
# calling this method, otherwise the changes remain confi-#
# ned to the internal structures of the segment (update() #
# dumps them into the data area). Note that "high level"  #
# methods, like those in the JPEG_<segment name>.pl files,#
# are supposed to call update() on their own.             #
###########################################################
sub save {
    my ($this, $filename) = @_;
    # fail immediately if "read_only" is set
    return undef if $this->{read_only};
    # if $filename is undefined, it defaults to the original name
    $filename = $this->{filename} unless defined $filename;
    # Open an IO handler for output on a file named $filename
    # or on an in-memory variable pointed to by $filename.
    # Use an indirect handler, which is closed authomatically
    # when it goes out of scope (so, no need to call close()).
    # If open fails, it returns false and sets the special
    # variable $! to reflect the system error.
    open(my $out, '>', $filename) || return undef;
    # Legacy systems might need an explicit binary open.
    binmode($out);
    # For each segment in the segment list, write the content of
    # the data area (including the preamble when needed) to the
    # IO handler. Save the results of each output for later testing.
    my @results = map { $_->output_segment_data($out) } @{$this->{segments}};
    # return undef if any print failed, true otherwise
    return (scalar grep { ! $_ } @results) ? undef : 1;
}

###########################################################
# This method takes care to open a file handle pointing   #
# to the JPEG object specified by $file_input. If the     #
# "file name" is a scalar reference instead, it is saved  #
# in the "handle" member (and it must be treated accor-   #
# dingly in the following). Nothing is actually read now; #
# if opening fails, the routine dies with a message.      #
###########################################################
sub open_input {
    my ($this, $file_input) = @_;
    # protect against undefined values
    $this->die('Undefined input') unless defined $file_input;
    # scalar references: save the reference in $this->{handle}
    # and save a self-explicatory string as file name
    if (ref $file_input eq 'SCALAR') {
	$this->{handle}   = $file_input;
	$this->{filename} = '[in-memory JPEG stream]'; }
    # real file: we need to open the file and complain if this is
    # not possible (legacy systems might need an explicity binary
    # open); then, the file name of the original file is saved.
    else {
	open($this->{handle}, '<', $file_input) ||
	    $this->die("Open error on $file_input: $!");
	binmode($this->{handle});
	$this->{filename} = $file_input; }
}

###########################################################
# This method is the counterpart of "open". Actually, it  #
# does something only for real files (because we do not   #
# want to close in-memory scalars ....).                  #
###########################################################
sub close_input {
    my ($this) = @_;
    # $this->{handle} should really be a reference to something
    return unless ref $this->{handle};
    # a ref to a scalar: we do not want to close in-memory scalars
    return if ref $this->{handle} eq 'SCALAR';
    # the default action corresponds to closing the filehandle
    close $this->{handle};
}

###########################################################
# This method returns a portion of the input file (speci- #
# fied by $offset and $length). It is necessary to mask   #
# how data reading is actually implemented. As usual, it  #
# dies on errors (but this is trapped in the constructor).#
# This method returns a scalar reference; if $offset is   #
# just "LENGTH", the input length is returned instead.    #
# A length <= 0 is ignored (ref to empty string).         #
###########################################################
sub get_data {
    my ($this, $offset, $length) = @_;
    # a shorter name for the file handle
    my $handle = $this->{handle};
    # understand if this is a file or a scalar reference
    my $is_file = ref $handle eq 'GLOB';
    # if the first argument is just the string 'LENGTH',
    # return the input length instead
    return ($is_file ? -s $handle : length $$handle) if $offset eq 'LENGTH';
    # this is the buffer to be returned at the end
    my $data = '';
    # if length is <= zero return a reference to an empty string
    return \ $data if $length <= 0;
    # if we are dealing with a real file, we need to seek to the
    # requested position, then read the appropriate amount of data
    # (and throw an error if reading failed).
    if ($is_file) {
	seek($handle, $offset, 0) ||
	    $this->die("Error while seeking in  $this->{filename}");
	my $read = read $handle, $data, $length;
	$this->die("Read error in  $this->{filename}")
	    if ! defined $read || $read < $length; }
    # otherwise, we are dealing with a scalar reference, and
    # everything is much simpler (this can't fail, right?)
    else { $data = substr $$handle, $offset, $length; }
    # return a reference to read data
    return \ $data;
}

###########################################################
# This method searches for segments in the input JPEG.    #
# When a segment is found, the corresponding data area is #
# read and used to create a segment object (the ctor of   #
# this object takes care to decode the relevant data).    #
# The object is then inserted into the "segments" hash,   #
# with a code-related key. Raw (compressed) image data    #
# are stored in "fake" segments, just for simplicity.     #
# ------------------------------------------------------- #
# There is now an argument, set equal to the second argu- #
# ment of the constructor. If it is defined, only match-  #
# ing segments are parsed. Also, if read_only is set,     #
# only "interesting" segments are saved and everything    #
# after the Start Of Scan is neglected.                   # 
#=========================================================#
# Structure of a generic segment:                         #
# 2 bytes  segment marker (the first byte is always 0xff) #
# 2 bytes  segment_length (it doesn't include the marker) #
#               .... data (segment_length - 2 bytes)      #
#=========================================================#
# The segment length (2 bytes) has a "Motorola" (big end- #
# ian) endianness (byte alignement), that is it starts    #
# with the most significant digit. Note that the segment  #
# length marker counts its own length (i.e., after it     #
# there are only segment_length-2 bytes).                 #
#=========================================================#
# Some segments do not have data after them (not even the #
# length field, they are pure markers): SOI, EOI and the  #
# RST? restart segments. Scans (started by a SOS segment) #
# are followed by compressed data, with possibly inter-   #
# leaved RST segments: raw data must be searched with a   #
# dedicated routine because they are not envelopped.      #
#=========================================================#
# Ref: "Digital compression and coding of continuous-tone #
#       still images: requirements and guidelines",       #
#      CCITT, 09/1992, sec. B.1.1.4, pag. 33.             #
###########################################################
sub parse_segments {
    my ($this, $regex) = @_;
    # prepare another hash to reverse the JPEG markers lookup
    my %JPEG_MARKER_BY_CODE = reverse %JPEG_MARKER;
    # an offset in the input object, and a variable with its size
    my $offset = 0;
    my $isize  = $this->get_data('LENGTH');
    # don't claim empty files are valid JPEG pictures
    $this->die('Empty file') unless $isize;
    # loop on input data and find all of its segment
    while ($offset < $isize) {
	# search for the next JPEG marker, giving the segment type
	(my $marker, $offset) = $this->get_next_marker($offset);
	# Die on unknown markers
	$this->die(sprintf 'Unknown marker found: 0x%02x (offset $offset)',
		   $marker) unless exists $JPEG_MARKER_BY_CODE{$marker};
	# save the current offset (beginning of data)
	my $start = $offset;
	# calculate the name of the marker
	my $name = $JPEG_MARKER_BY_CODE{$marker};
	# determine the parse flag
	my $flag = ($regex && $name !~ /$regex/) ? 'NOPARSE' : undef;
	# SOI, EOI and ReSTart are dataless segments
	my $length = 0; goto DECODE_LENGTH_END if $name =~ /^RST|EOI|SOI/;
      DECODE_LENGTH_START:
	# we need at least two bytes here
	$this->die('Segment size not found') unless $isize > $offset + 2;
	# decode the length of this application block (2 bytes).
	# This is always in big endian ("Motorola") style, that
	# is the first byte is the most significant one.
	$length = unpack 'n', ${$this->get_data($offset, 2)};
	# the segment length includes the two aforementioned
	# bytes, so the length must be at least two
	$this->die('JPEG segment too small') if $length < 2;
      DECODE_LENGTH_END:
	# we need at least $length bytes here
	$this->die('Segment data not found') unless $isize >= $offset+$length;
	# pass the data to a segment object and store it, unless
	# the "read_only" member is set and $flag is "NOPARSE".
	# (don't pass $flag to dataless segments, it is just silly).
	push @{$this->{segments}}, new Image::MetaData::JPEG::Segment
	    ($name, $this->get_data($start + 2, $length - 2),
	     $length ? $flag : undef) unless $this->{read_only} && $flag;
	# update offset
	$offset += $length;
	# When you find a SOS marker or a RST marker there is a special
	# treatement; if "read_only" is set, we neglect the rest of the
	# input. Otherwise, we need a special routine
	if ($name =~ /SOS|^RST/) {
	    $offset = $isize, next if $this->{read_only};
	    $offset = $this->parse_ecs($offset); }
      DECODE_PAST_EOI_GARBAGE:
	# Try to intercept underground data stored after the EOI segment;
	# I have found images which store multiple reduced versions of
	# itself after the EOI segment, as well as undocumented binary
	# and ascii data. Save them in a pseudo-segment, so that they
	# can be restored (take "read_only" into account).
	if ($name eq 'EOI' && $offset < $isize) {
	    my $len = $isize - $offset;
	    push @{$this->{segments}}, new Image::MetaData::JPEG::Segment
		('Post-EOI', $this->get_data($offset, $len), 'NOPARSE')
		unless $this->{read_only};
	    $offset += $len;
	}
    }
}

###########################################################
# This method searches for the next JPEG marker in the    #
# stream being parsed. A marker is always assigned a two  #
# byte code: an 0xff byte followed by a byte which is not #
# 0x00 nor 0xff. Any marker may optionally be preceeded   #
# by any number of fill bytes (padding of the previous    #
# segment, I suppose), set to 0xff. Most markers start    #
# marker segments containing a related group of parame-   #
# ters; some markers stand alone. The return value is a   #
# list containing the numeric value of the second marker  #
# byte and an offset pointing just after it.              #
# ------------------------------------------------------- #
# An old version of "Arles Image Web Page Creator" had a  #
# bug which caused the application to generate JPEG's     #
# with illegal comment segments, reportedly due to a bug  #
# in the Intel JPEG library the developers used at that   #
# time (these segments had to 0x00 bytes appended). It is #
# true that a JPEG file with garbage between segments is  #
# to be considered invalid, but some libraries like IJG's #
# try to forgive, so we try to forgive too, if the amount #
# of garbage is not too large ...                         #
#=========================================================#
# Ref: "Digital compression and coding of continuous-tone #
#       still images: requirements and guidelines",       #
#      CCITT, 09/1992, sec. B.1.1.2, pag. 31.             #
#=========================================================#
sub get_next_marker {
    my ($this, $offset) = @_;
    my $punctuation = chr $JPEG_PUNCTUATION; my $garbage = 0;
    # this is the upper limit to $offset
    my $length = $this->get_data('LENGTH');
    # $offset should point at the beginning of a new segment,
    # so the next byte should be 0xff. However, sometimes garbage
    # slips in ... Forgive this bug if garbage is not too much
    $offset < $length && ${$this->get_data($offset, 1)} eq $punctuation 
	? last : (++$garbage, ++$offset) for (0..10);
    $this->die('Next marker not found') unless $length - $offset > 1;
    # it is assumed that we are now at the beginning of
    # a new segment, so the next byte must be 0xff.
    my $marker_byte = ${$this->get_data($offset++, 1)};
    $this->die(sprintf 'Unknown punctuation (0x%02x) at offset 0x%x',
	       ord($marker_byte), $offset) if $marker_byte ne $punctuation;
    # report about garbage, unless we died
    $this->warn("Skipping $garbage garbage bytes") if $garbage;
    # next byte can be either the marker type or a padding
    # byte equal to 0xff (skip it if it's a padding byte)
    $marker_byte = ${$this->get_data($offset++, 1)}
    while $marker_byte eq $punctuation;
    # return the marker we have found (no check on its validity),
    # as well as the offset to the next byte in the JPEG stream
    return (ord($marker_byte), $offset);
}

###########################################################
# This method reads in a compressed (entropy coded) data  #
# segment (ECS) and saves it as a "pseudo" segment. The   #
# argument is the current offset in the in-memory JPEG    #
# stream, the result is the updated offset. These pseudo  #
# segments can be found after a Start-Of-Scan segment,    #
# and, if restart is enabled, they can be interleaved     #
# with restart segments (RST). Indeed, an ECS is not a    #
# real segment, because it does not start with a marker   #
# and its length is not known a priori. However, it is    #
# easy to detect its end since a regular marker cannot    #
# appear inside it. In practice, data in an ECS are coded #
# in such a way that a 0xff byte can only be followed by  #
# 0x00 (invalid marker) or 0xff (padding).                #
#=========================================================#
# WARNING: when restart is enabled, usually the file con- #
# tains a lot of ECS and RST. In order not to be too slow #
# we keep the restart marker embedded in row data here.   #
#=========================================================#
# Ref: "Digital compression and coding of continuous-tone #
#       still images: requirements and guidelines",       #
#      CCITT, 09/1992, sec. B.1.1.5, pag. 33.             #
###########################################################
sub parse_ecs {
    my ($this, $offset) = @_;
    # A title for a raw data block ('ECS' must be there)
    my $ecs_name = 'ECS (Raw data)';
    # transform the JPEG punctuation value into a string
    my $punctuation = chr $JPEG_PUNCTUATION;
    # create a string containing the character which can follow a
    # punctuations mark without causing the ECS to be considered
    # terminated. This string must contain at least the null byte and
    # the punctuation mark itself. But, for efficiency reasons, we are
    # going to include also the restart markers here.
    my $skipstring = $punctuation . chr 0x00;
    $skipstring .= chr $_ for ($JPEG_MARKER{RST0} .. $JPEG_MARKER{RST7});
    # read in everything till the end of the input
    my $length = $this->get_data('LENGTH');
    my $buffer = $this->get_data($offset, $length - $offset);
    # find the next 0xff byte not followed by a character of $skipstring
    # from $offset on. It is better to use pos() instead of taking a
    # substring of $$buffer, because this copy takes a lot of space. In
    # order to honour the position set by pos(), it is necessary to use
    # "g" in scalar context. My benchmarks say this is almost as fast as C.
    pos($$buffer) = 0; scalar $$buffer =~ /$punctuation[^$skipstring]/g;
    # trim the $buffer at the byte before the punctuation mark; the
    # position of the last match can be accessed through pos(); if no
    # match is found, complain but do not fail (similar behaviour to that
    # of the 'xv' program); the file is however corrupt and unusable.
    pos($$buffer) ? substr($$buffer, pos($$buffer) - 2) = ''
	: $this->warn('Premature end of JPEG stream');
    # push a pseudo segment among the regular ones (do not parse it)
    push @{$this->{segments}}, new Image::MetaData::JPEG::Segment
	($ecs_name, $buffer, 'NOPARSE');
    # return the updated offset
    return $offset + length $$buffer;
}

###########################################################
# This method creates a list containing the references    #
# (or their indexes in the segment references list, if    #
# the second argument is 'INDEXES') of those segments     #
# whose name matches a given regular expression.          #
# The output can be invalid after adding/removing any     #
# segment. If $regex is undefined or evaluates to the     #
# empty string, this method returns all indexes.          #
###########################################################
sub get_segments {
    my ($this, $regex, $do_indexes) = @_;
    # fix the regular expression to '.' if undefined or set to the
    # empty string. I do this because I want to avoid the stupid
    # behaviour of m//; from `man perlop`: if the pattern evaluates
    # to the empty string, the last successfully matched regular
    # expression is used instead; if no match has previously succeeded,
    # this will (silently) act instead as a genuine empty pattern
    $regex = '.' unless defined $regex && length $regex > 0;
    # get the list of segment references in this file
    my $segments = $this->{segments};
    # return the list of matched segments
    return (defined $do_indexes && $do_indexes eq 'INDEXES') ?
	grep { $$segments[$_]->{name} =~ /$regex/ } 0..$#$segments :
	grep { $_->{name} =~ /$regex/ } @$segments;
}

###########################################################
# This method erases from the internal segment list all   #
# segments matching the $regex regular expression. If     #
# $regex is undefined or evaluates to the empty string,   #
# this method throws an exception, because I don't want   #
# the user to erase the whole file just because he/she    #
# did not understand what he was doing. The apocalyptic   #
# behaviour can be forced by setting $regex = '.'. One    #
# must remember that it is not wise to drop non-metadata  #
# segments, because this in general invalidates the file. #
# As a special case, if $regex == 'METADATA', all APP*    #
# and COM segments are erased.                            #
###########################################################
sub drop_segments {
    my ($this, $regex) = @_;
    # refuse to work with empty or undefined regular expressions
    $this->die('regular expression not specified')
	unless defined $regex && length $regex > 0;
    # if $regex is 'METADATA', convert it
    $regex = '^(APP\d{1,2}|COM)$' if $regex eq 'METADATA';
    # rewrite the segment list keeping only segments not matching
    # $regex (see get_segments for further considerations).
    @{$this->{segments}} = 
	grep { $_->{name} !~ /$regex/ } @{$this->{segments}};
}

###########################################################
# This method inserts the segments referenced by $segref  #
# into the current list of segments at position $pos. If  #
# $segref is undefined, the method fails silently. If     #
# $pos is undefined, the position is chosen automatically #
# (using find_new_app_segment_position); if $pos is out   #
# of bound, an exception is thrown; this happens also if  #
# $pos points to the first segment, and it is SOI.        #
# $segref may be a reference to a single segment or a     #
# reference to a list of segment references; everything   #
# else throws an exception. If overwrite is defined, it   #
# must be the number of segs to overwrite during splice.  #
###########################################################
sub insert_segments {
    my ($this, $segref, $pos, $overwrite) = @_;
    # do nothing if $segref is undefined or is not a reference
    return unless ref $segref;
    # segref may be a reference to a segment or a reference
    # to a list; we must turn it into a reference to a list
    $segref = [ $segref ] unless ref $segref eq 'ARRAY';
    # check that all elements in the list are segment references
    ref $_ eq 'Image::MetaData::JPEG::Segment' ||
	$this->die('$segref is not a reference') for @$segref;
    # calculate a convenient position if the user neglects to;
    # remember to pass the new segment name as an argument
    $pos = $this->find_new_app_segment_position
	(exists $$segref[0] ? $$segref[0]->{name} : undef) unless defined $pos;
    my $max_pos = -1 + $this->get_segments();
    # fail if $pos is negative or out-of-bound;
    $this->die("out-of-bound position $pos [0, $max_pos]")
	if $pos < 0 || $pos > $max_pos;
    # fail if $pos points to the first segment and it is SOI
    $this->die('inserting on start-of-image is forbidden')
	if $pos == 0 && $this->{segments}->[0]->{name} eq 'SOI';
    # do the actual insertion (one or multiple segments);
    # if overwrite is defined, it must be the number of
    # segments to overwrite during the splice.
    $overwrite = 0 unless defined $overwrite;
    splice @{$this->{segments}}, $pos, $overwrite, @$segref;
}

###########################################################
# This method finds a position for a new application or   #
# comment segment to be placed in the file. The algorithm #
# is the following: the position is chosen immediately    #
# before the first (or after the last) element of some    #
# list, provided that the list is not empty, otherwise    #
# the next list is taken into account:                    #
#  -) [for COM segments only] try after 'COM' segments;   #
#     otherwise try after all APP segments;               #
#  -) [for APPx segments only] try after the last element #
#     of the list of APPy's (with y = x..0, in sequence); #
#     otherwise try before the first element of the list  #
#     of APPy's (with y = x+1..15, in sequence);          #
#  -) try before the first DHP segment                    #
#  -) try before the first SOF segment                    #
# If all these approaches fail, this method returns the   #
# position immediately after the SOI segment (i.e., 1).   #
# ------------------------------------------------------- #
# The argument must be the name of the segment to be      #
# inserted (it defaults to 'COM', producing a warning).   #
###########################################################
sub find_new_app_segment_position {
    my ($this, $name) = @_;
    # if name is not specified, issue a warning and set 'COM'
    $this->warn('Segment name not specified: using COM'), $name = 'COM'
	unless $name;
    # setting $name to something else than 'COM' or 'APPx' is an error
    $this->die("Unknown segment name ($name)")
	unless $name =~ /^(COM|APP([0-9]|1[0-5]))$/;
    # just in order to avoid a warning for half-read files
    # with an incomplete set of segments, let us make sure
    # that no position is past the segment array end
    my $last_segment = -1 + $this->get_segments();
    my $safe = sub { ($last_segment < $_[0]) ? $last_segment : $_[0] };
    # this private function returns a list containing the
    # indexes of the segments whose name matches the argument
    my $list = sub { $this->get_segments('^'.$_[0].'$', 'INDEXES') };
    # if there are already some 'COM' segments, let us put the new COM
    # segment immediately after them; otherwise try after all APP segments
    if ($name =~ /^COM/) {
	return &$safe(1+$_) for reverse &$list('COM');
	return &$safe(1+$_) for reverse &$list('APP.*'); }
    # if $name is APPx, try after the last element of the list of APPy's
    # (with y = x .. 0, in sequence); if all these fail, try before the
    # first element of the list of APPy's (with y = x+1..15, in sequence)
    if ($name =~ /^APP(.*)$/) {
	for (reverse 0..$1) {return &$safe(1+$_) for reverse &$list("APP$_");};
	for (1+$1..15) { return &$safe($_) for &$list("APP$_"); }; }
    # if all specific tests failed, try with the
    # first DHP segment or the first SOF segment
    return &$safe($_) for &$list('DHP');
    return &$safe($_) for &$list('SOF');
    # if even this fails, try after start-of-image (just in order
    # to avoid a warning for half-read files with not even two
    # segments (they cannot be saved), return 0 if necessary)
    return &$safe(1);
}

###########################################################
# Load other parts for this package. In order to avoid    #
# that this file becomes too large, only general interest #
# methods are written here.                               #
###########################################################
require 'Image/MetaData/JPEG/access/various.pl';
require 'Image/MetaData/JPEG/access/comments.pl';
require 'Image/MetaData/JPEG/access/app1_exif.pl';
require 'Image/MetaData/JPEG/access/app13.pl';

# successful package load
1;
