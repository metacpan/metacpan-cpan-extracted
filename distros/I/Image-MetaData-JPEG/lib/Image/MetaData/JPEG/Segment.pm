###########################################################
# A Perl package for showing/modifying JPEG (meta)data.   #
# Copyright (C) 2004,2005,2006 Stefano Bettelli           #
# See the COPYING and LICENSE files for license terms.    #
###########################################################
package Image::MetaData::JPEG::Segment;
use Image::MetaData::JPEG::data::Tables
    qw(:JPEGgrammar :Endianness :RecordTypes);
use Image::MetaData::JPEG::Backtrace;
use Image::MetaData::JPEG::Record;
no  integer;
use strict;
use warnings;

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
	       ($message, "Fatal error" . $this->info(), $this);}
sub info { my ($this) = @_; my $name = $this->{name} || '<no name>';
	   return " [segment type $name]"; }

###########################################################
# JPEG segment header constructor. Its arguments are: the #
# segment type (a multicharacter string, not the marker), #
# a reference to a raw data buffer and a parse flag. The  #
# raw buffer is saved internally through its reference    #
# (no copy is done). If its parse flag does not match     #
# "NOPARSE", and its type is parseable, the Segment has   #
# its key-value pairs extracted to JPEG::Record's in the  #
# 'records' list.                                         #
#=========================================================#
# The first four bytes in the Segment mean:               #
#                                                         #
#  2 bytes  segment marker (0xff..)                       #
#  2 bytes  length (including this value)                 #
#                                                         #
# The marker is a two byte value, whose first byte is     #
# always 0xff. The value of the second byte defines the   #
# segment type. It is assumed that the buffer which is    #
# passed to this constructor DOES NOT contain these four  #
# bytes; in fact, the segment type can be deduced by its  #
# symbolic name (first argument), and the buffer size can #
# be calculated with the length() function. This simpli-  #
# fies a lot of repetitive code, but it must be kept in   #
# mind when the file is written back to the filesystem.   #
#=========================================================#
# $this->{endianness} (a private field) contains the      #
# current endianness, i.e. the endianness to be used for  #
# reading the next values while parsing the data area.    #
# Its significant is therefore only transient, and it is  #
# set to undef at the end of the constructor.             #
#=========================================================#
# $this->{error} is normally set to "undef". If, however, #
# an error occurred during the parsing stage in the cons- #
# tructor, this variable is set to an error message. The  #
# intended use is the following: a Segment with errors    #
# can be inspected (partially, of course, because parsing #
# did not terminate correctly) but not modified (that is, #
# the update method, which overwrites the area pointed to #
# by $this->{dataref}, must be inhibited): it can only be #
# rewritten to disk as it is.                             #
###########################################################
sub new {
    my ($pkg, $name, $dataref, $flag) = @_;
    # if $dataref is undef, point it to a *modifiable* empty string
    my $this = bless {
	name       => $name,
	dataref    => defined $dataref ? $dataref : \ (my $ns = ''),
	records    => [],
	error      => undef,
	endianness => undef,
    }, $pkg;
    # die on various error conditions
    $this->die('Invalid segment name')  unless defined $name && ! ref $name;
    $this->die('Invalid data reference') if defined $dataref && ! ref $dataref;
    # parse the segment (pass the $flag)
    $this->parse($flag);
    # return a reference to the constructed object
    return $this;
}

###########################################################
# This method parses or reparses the current segment. It  #
# only dispatches the flow to specific subroutines based  #
# on the segment name. The error flag is reset to undef   #
# before parse_*, so that, at the end, it reflects only   #
# errors occurred during this parse session. If the $flag #
# argument is set to "NOPARSE", this method simulates an  #
# error and refuses to proceed further. The parsed data   #
# array "@records" is flushed when entering this routine. #
#=========================================================#
# Segment parsing is enclosed in an eval block, so that   #
# errors are not fatal (they work as trapped exceptions,  #
# and the die-string is converted into a message).        #
#=========================================================#
# See also the notes in the constructor about the private #
# var. $this->{endianness} and the use of $this->{error}. #
###########################################################
sub parse {
    my ($this, $flag) = @_;
    # locally set endianness to big endian
    local $this->{endianness} = $BIG_ENDIAN;
    # reset the error flag and clear the data set
    $this->{error}   = undef; 
    $this->{records} = [];
    # call the specific parse routines inside an eval block,
    # so that errors are not fatal...
    eval {
	# if $flag matches "NOPARSE", we don't need to parse
	goto STOP_PARSING if ($flag && $flag =~ /NOPARSE/);
        # this is a stupid Perl-style switch
	for ($this->{name}) {
	    # parse all informative tags
	    $_ eq 'COM'   ? $this->parse_com()     : # User comments
	    $_ eq 'APP0'  ? $this->parse_app0()    : # JFIF
	    $_ eq 'APP1'  ? $this->parse_app1()    : # Exif or XMP
	    $_ eq 'APP2'  ? $this->parse_app2()    : # FPXR or ICC_Prof
	    $_ eq 'APP3'  ? $this->parse_app3()    : # Additonal metadata
	    $_ eq 'APP4'  ? $this->parse_unknown() : # HPSC
	    $_ eq 'APP12' ? $this->parse_app12()   : # PreExif ascii meta
	    $_ eq 'APP13' ? $this->parse_app13()   : # IPTC and Photoshop
	    $_ eq 'APP14' ? $this->parse_app14()   : # Adobe tags
	    # parse all JPEG image tags (SOI, EOI and RST* are trivial)
	    /^(SOI|EOI|RST)$/ ? do { /nothing/ }   :
	    $_ eq 'DQT'   ? $this->parse_dqt()     :
	    $_ eq 'DHT'   ? $this->parse_dht()     :
	    $_ eq 'DAC'   ? $this->parse_dac()     :
	    /^SOF|DHP/    ? $this->parse_sof()     :
	    $_ eq 'SOS'   ? $this->parse_sos()     :
	    $_ eq 'DNL'   ? $this->parse_dnl()     :
	    $_ eq 'DRI'   ? $this->parse_dri()     :
	    $_ eq 'EXP'   ? $this->parse_exp()     :
	    # this is the fallback case
	    $this->parse_unknown(); };
      STOP_PARSING: 
    };
    # parsing was ok if no error was catched by the eval.
    # Update the "error" member here to reflect this fact.
    $this->{error} = $@ if $@;
}

###########################################################
# This method re-executes the parsing of a segment after  #
# changing the segment nature (well, its name). This is   #
# very handy if you have a JPEG file with a correct appli-#
# cation segment exception made for its name. I used it   #
# the first time for a file having an ICC_profile segment #
# (usually in APP2) stored as APP13. Note that the name   #
# of the segment is permanently changed, so, if the file  #
# is rewritten to disk, it will be "correct".             #
###########################################################
sub reparse_as {
    my ($this, $new_name) = @_;
    # change the nature of this segment by overwriting its name
    $this->{name} = $new_name;
    # re-execute the parsing
    $this->parse();
}

###########################################################
# This method is the entry point for dumping the data     #
# structures stored in the records into the private data  #
# area. This method needs to be called before rewriting a #
# file to the disk, if any record was changed/added/elimi-#
# nated. The routine dispatches to more specific methods. #
# ------------------------------------------------------- #
# A segment with errors cannot be updated (a security     #
# measure: do not update what you do not understand).     #
# Entropy-coded segments or past-the-end garbage do not   #
# need being updated: the method returns immediately.     #
# ------------------------------------------------------- #
# update() saves a reference to the old segment data area #
# and restores it if the specialised update routine fails.#
# This only generate a warning! Are there cleverer ways   #
# to handle this case? It is however better to have a     #
# corrupt object in memory, than a corrupt object written #
# over the original. Currently, this is restricted to the #
# possibility that an updated segment becomes too large.  #
###########################################################
sub update {
    my ($this) = @_;
    # get the name of the segment
    my $name = $this->{name};
    # return immediately if this is an entropy-coded segment or 
    # past-the-end garbage. There is no need to "update" them
    return if $name =~ /ECS|Post-EOI/;
    # if the segment was not correctly parsed, warn and return
    $this->die('This segment is faulty') if $this->{error};
    # this might come also from 'NOPARSE'
    $this->die('This segment has no records') unless @{$this->{records}};
    # save a copy of the old data area.
    my $old_content = $this->{dataref};
    # blank the data area (do not assign directly to a reference to the
    # null string, since it is not modifiable in some implementations!)
    $this->{dataref} = \ (my $ns = '');
    # an error variable for specific update routines
    my $error = undef;
    # call more specific routines for segments we know how
    # to update. Generate an error if the type is not managed.
    # (SOI, EOI and RST* are trivial and should not get here)
    for ($name) {
	$error = $this->dump_com(),   next if $_ eq 'COM';
	$error = $this->dump_app1(),  next if $_ eq 'APP1';
	$error = $this->dump_app13(), next if $_ eq 'APP13';
	$error = "Update routine for '$_' not yet implemented"; }
    # get the size of the new data area
    my $length = $this->size();
    # if new size is too large, set the error flag
    $error = "Segment '${name}' too large (len=${length}, " .
	"max=${JPEG_SEG_MAX_LEN})" if $length > $JPEG_SEG_MAX_LEN;
    # if the update failed, revert to the old content
    if ($error) {
	$this->warn("Update failed [$error]: reverting to old content ...");
	$this->{dataref} = $old_content; }
}

###########################################################
# This method outputs the current segment data area into  #
# a file handle. The segment "preamble" is prepended, ex- #
# ception made for raw data (scans). The preamble always  #
# includes the 0xff byte followed by the segment marker.  #
# A Segment which can accept real data also requires a    #
# two-byte data count. The return value is the error      #
# status of the print calls.                              #
# ------------------------------------------------------- #
# If the segment size is too large, a warning is printed  #
# and 0 is returned (this can make the file invalid);     #
# this is however just for debugging, I hope ....         #
#=========================================================#
# Note that the data area of a segment can be void and,   #
# nonetheless, the segment might require a segment length #
# word (e.g., a "" comment). In practise, the only seg-   #
# ments not needing the length word are SOI, EOI and RST*.#
###########################################################
sub output_segment_data {
    my ($this, $out) = @_;
    # collect the name of the segment and the length of the data area
    my $name   = $this->{name};
    my $length = $this->size();
    # Check segment length and throw an exception in case it is too
    # large. Do not run the check for raw data or past-the-end data.
    $this->die(sprintf('Segment %s too large (len=%d, max=%d)',
		       $this->{name}, $length, $JPEG_SEG_MAX_LEN))
	if $length > $JPEG_SEG_MAX_LEN && $name !~ /ECS|Post-EOI/;
    # prepare the segment header (not needed for a raw data segment)
    my $preamble = ( $name =~ /ECS|Post-EOI/ ? "" :
		     pack("CC", $JPEG_PUNCTUATION, $JPEG_MARKER{$name}) );
    # prepare the length word (not all segment types need it)
    $preamble .= pack("n", 2 + $length)
	unless $name =~ /SOI|EOI|RST|ECS|Post-EOI/;
    # output the preamble and the data buffer (return the status)
    return print {$out} $preamble . $this->data(0, $length);
}

###########################################################
# This method shows the content of the segment. It prints #
# a header, then inspects the directory recursively.      #
###########################################################
sub get_description {
    my ($this) = @_;
    # prepare the marker and the error message
    my $amarker = $JPEG_MARKER{$this->{name}};
    my $error   = $this->{error}; chomp $error if defined $error;
    # prepare a header for this segment (was Segment_Banner)
    my $description = sprintf("%7dB ", $this->size()) .
	($amarker ? sprintf "<0x%02x %5s>", $amarker, $this->{name} :
	 sprintf "<%10s>", $this->{name} ) .
	 ($error ? " {Faulty segment:\n $error}" : "") . "\n";
    # a list for successive keys for numeric tag descriptions
    my $names = [ $this->{name} ];
    # show all the records we have in our structures (recursively)
    $description .= $this->show_directory($this->{records}, $names);
}

###########################################################
# This method shows the content of a record directory in  #
# a segment; the first argument is a record list refe-    #
# rence; the second argument is a list to a list of names #
# used to resolve numeric tags. A string is returned.     #
###########################################################
sub show_directory {
    my ($this, $records, $names) = @_;
    # protection againts invalid references
    return "" unless ref $records eq 'ARRAY';
    # prepare the string to be returned at the end
    my $description = "";
    # an initially empty list for remembering sub-dirs
    my @subdirs = ();
    # show all records in this directory
    foreach (@$records) {
	# show the record content
	$description .= $_->get_description($names);
	# if this is a subdir, remember its reference
	push @subdirs, $_ if $_->get_category() eq 'p';
    }
    # for every subdir we found, recurse
    foreach (@subdirs) {
	# get the directory name and reference
	my ($dir_name, $directory) = ($_->{key}, $_->get_value());
	# update the $names list
	push @$names, $dir_name;
	# print a sub-header for this directory
	$description .= Directory_Banner($names, $directory);
	# show the sub directory
	$description .= $this->show_directory($directory, $names);
	# pop the last dir name from @$names
	pop @$names;
    }
    # return the string we cooked up
    return $description;
}

###########################################################
# This helper function returns a string to be used as a   #
# generic header for a segment directory.                 #
###########################################################
sub Directory_Banner {
    my ($names, $dirref) = @_;
    # protections against invalid references
    $names = [] unless ref $names eq 'ARRAY';
    $dirref = [], push @$names, "[invalid]" unless ref $dirref eq 'ARRAY';
    # prepare parts of the description
    my $buffer = join " --> ", @$names;
    my $decoration = "*" x 10;
    my $indentation = " \t" x scalar @$names;
    # complete the description and return it
    my $description = sprintf "%s%s %s %s (%2d records)", 
    $indentation, $decoration, $buffer, $decoration, scalar @$dirref;
    return $description . "\n";
}

###########################################################
# This helper method is used to test a size condition,    #
# i.e. that there is enough data (or exactly some amount  #
# of data) in the data buffer. If the test fails, it dies #
###########################################################
sub test_size {
    my ($this, $required, $message) = @_;
    # positive $require: test not greater
    return if $required >= 0 && $this->size() >= $required;
    # negative $require: test equality (on -$required)
    return if $required <  0 && $this->size() == (- $required);
    # if test fails, call die and hope it is intercepted
    my $precise = ""; $message = defined $message ? "($message)" : "";
    $required *= -1, $precise = "exactly " if $required < 0;
    $this->die(sprintf 'Size mismatch in segment %s %s:'
	       . ' required %s%dB, found %dB.', $this->{name},
	       $message, $precise, $required, $this->size());
}

###########################################################
# This is a helper method returning the size in bytes of  #
# the data area, i.e. that pointed to by $this->{dataref} #
###########################################################
sub size { return length ${$_[0]{dataref}}; }

###########################################################
# This helper method returns a substring of the data area #
# (the arguments are offset and length).                  #
###########################################################
sub data { substr(${$_[0]{dataref}}, $_[1], $_[2]); }

###########################################################
# This helper method writes into the segment data area.   #
# The first argument is a scalar or a scalar reference,   #
# which (or whose content) is appended to the current     #
# buffer. The method returns the appended string length.  #
###########################################################
sub set_data {
    my ($this, $addenda) = @_;
    # get a reference to new data (remember that the
    # first argument can be a scalar or a scalar reference)
    my $addref = (ref $addenda) ? $addenda : \$addenda;
    # append the new data through the ref
    ${$this->{dataref}} .= $$addref;
    # return the amount of appended data
    return length $$addref;
}

###########################################################
# This private method processes the arguments for search  #
# routines, like search_record and provide_subdirectory.  #
#  1) a start directory is chosen by looking at the last  #
#     argument: if it is an ARRAY ref it is popped out    #
#     and used, otherwise the top-level directory (i.e.,  #
#     $this->{records}) is selected;                      #
#  2) a $keystring is created by joining all remaining    #
#     arguments on '@', then this string is exploded into #
#     a @keylist on the same character;                   #
#  3) the start directory and the @keylist is returned.   #
###########################################################
sub process_search_args {
    my $this = shift;
    # empty list ==> push a single undefined value 
    @_ = (undef) unless @_;
    # initialise the search directory: use the last argument if
    # it is an array reference, the top-level directory otherwise
    my $directory = ref $_[$#_] eq 'ARRAY' ? pop : $this->{records};
    # delete all undefined or "false" arguments
    @_ = grep { defined $_ } @_;
    # join all remaining arguments
    my $keystring = join('@', @_);
    # split the resulting string on '@'
    my @keylist = split('@', $keystring);
    # delete all false arguments
    @keylist = grep { $_ } @keylist;
    # return processed arguments
    return ($directory, @keylist);
}

###########################################################
# This method searches for a record with a given key in a #
# given record directory, returning a reference to the    #
# record if the search was fruitful, undef otherwise.     #
# The search is specified as follows:                     #
#  1) a start directory is chosen by looking at the last  #
#     argument: if it is an ARRAY ref it is popped out    #
#     and used, otherwise the top-level directory (i.e.,  #
#     $this->{records}) is selected;                      #
#  2) a $keystring is created by joining all remaining    #
#     arguments on '@', then this string is exploded into #
#     a @keylist on the same character;                   #
#  3) these keys are used for an iterative search start-  #
#     ing from the initially chosen directory: all but    #
#     the last key must correspond to $REFERENCE records. #
# ------------------------------------------------------- #
# If $key is exactly "FIRST_RECORD" / "LAST_RECORD", the  #
# first/last record in the current directory is selected. #
###########################################################
sub search_record {
    my $this = shift;
    # transform the arguments
    my ($directory, @keylist) = $this->process_search_args(@_);
    # reset the searched $record to a fake record pointing to the root
    my $record = $this->create_record('Fake', $REFERENCE, \ $this->{records});
    # search iteratively with all elements in @keylist
    for my $key (@keylist) {
	# exit the loop as soon as a key is undefined
	($record = undef), last unless $key;
	# update the current $record
	$record =
	    # reserved key "FIRST_RECORD" returns first record
	    $key eq "FIRST_RECORD" ? $$directory[0] :
	    # reserved key "LAST_RECORD" returns last record
	    $key eq "LAST_RECORD" ? $$directory[$#$directory] :
	    # standard search (get first matching record or undef)
	    ((grep { $_->{key} eq $key } @$directory), undef)[0];
	# stop if $record is undefined or is not a $REFERENCE
	last unless $record && $record->get_category() eq 'p';
	# update $directory for next search
	$directory = $record->get_value(); }
    # return the search result
    return $record;
}

###########################################################
# A simple wrapper around search_record(): it returns the #
# record value if the search is ok, undef otherwise.      #
###########################################################
sub search_record_value {
    my $this = shift;
    # call search_record passing all arguments through
    my $record = $this->search_record(@_);
    # return the record value if record is defined
    return $record ? $record->get_value() : undef;
}

###########################################################
# This method looks for a path of subdirectories from a   #
# given record list. The treatment of arguments is simi-  #
# lar to that of search_record: all arguments are joined  #
# to form a path specification, which is followed, and    #
# the last directory (record list) is returned. An optio- #
# nal last argument may specify an initial directory for  #
# the search (this defaults to $this->{records}). If any  #
# subdir entry is not there, it is created on the fly.    #
###########################################################
sub provide_subdirectory {
    my $this = shift;
    # transform the arguments
    my ($dirref, @keylist) = $this->process_search_args(@_);
    # search iteratively with all elements in @keylist
    for my $key (@keylist) {
	# keys cannot be undefined
	$this->die('Undefined key') unless $key;
	# search the subdirectory record
	my $record = $this->search_record($key, $dirref) ||
	    $this->store_record($dirref, $key, $REFERENCE, \ []);
	# die if $record is not a $REFERENCE
	$this->die('Not a reference') unless $record->get_category() eq 'p';
	# update $dirref for next search
	$dirref = $record->get_value(); }
    # return the search result
    return $dirref;
}

###########################################################
# This method creates a (possibly multi-valued) JPEG seg- #
# ment record from a data buffer or from the segment data #
# area, and it is the lowest level record-related method, #
# the only one actually calling the JPEG::Record ctor.    #
# It needs the record identifier, the value type, [a sca- #
# lar reference to read data from] or [the offset of the  #
# memory to read in the data area], and an optional count.#
# A reference to the record is returned at the end .      #
#=========================================================#
# If a scalar reference is passed, no check is performed  #
# on the size of the referenced scalar, because it is as- #
# sumed that this is dealt with in the caller routine (be #
# sure that $count is correct in this case!), and all the #
# arguments are simply passed to the Record constructor.  #
# The correct endianness is read from the value of the    #
# current endianness, which is a private object member.   #
###########################################################
sub create_record {
    my ($this, $identifier, $type, $dataref, $count) = @_;
    # if the third argument is an offset, we need to convert it
    unless (ref $dataref) {
	# the data reference is indeed an offset
	my $offset = $dataref;
	# buffer length is calculated by the Record class
	my $length = Image::MetaData::JPEG::Record->get_size($type, $count);
	# for variable-length types, $count is the real length
	$length = $count if $length == 0;
	# replace the third argument with a scalar reference
	$dataref = \ $this->data($offset, $length);
	# update the offset through its alias (dangerous)
	# but don't complain if we have a read-only offset
	eval { $_[3] += $length; };
    }
    # call the record constructor and return its value (a reference)
    return new Image::MetaData::JPEG::Record
	($identifier, $type, $dataref, $count, $this->{endianness});
}

###########################################################
# This method is a wrapper for create_record returning    #
# the parsed value and NOT storing the record internally  #
# (for this reason we can set $identifier = 0). So, the   #
# arguments are: type, data reference, count. The data    #
# reference can be replaced by an offset, used to access  #
# the internal segment data buffer. If the offset is an   #
# lvalue, it is updated to point after the memory just    #
# read. The count can be undefined (it defaults to 1).    #
###########################################################
sub read_record {
    # @_ = (this, type, dataref/offset, count)
    my $this = shift;
    # invoke create_record: the first argument (the identifier)
    # is dummy, for the others we can use @_. Return the value
    return $this->create_record(0, @_)->get_value();
}

###########################################################
# This method creates a generic JPEG segment record just  #
# like read_record, stores it in the "records" list, and  #
# returns a reference to the newly created record. If the #
# offset is an lvalue, it is updated to point after the   #
# memory just read. See read_record for further details.  #
#=========================================================#
# A list reference can be prepended to the argument list; #
# in this case it is used instead of $this->{records}.    #
###########################################################
sub store_record {
    # @_ = (this, [record list,] identifier, type, dataref/offset, count)
    my $this = shift;
    # get a reference to the record list; but if next argument
    # is a reference, use it instead (and take it out of @_)
    my $records = $this->{records};
    $records = shift if ref $_[0];
    # create a new record and insert it into the record
    # list; we can use @_ for all the arguments.
    push @$records, $this->create_record(@_);
    # return a reference to the last record
    return $$records[$#$records];
}

###########################################################
# Load other parts for this package. In order to avoid    #
# that this file becomes too large, only general interest #
# methods are written here.                               #
###########################################################
require 'Image/MetaData/JPEG/parsers/parsers.pl';
require 'Image/MetaData/JPEG/dumpers/dumpers.pl';

# successful package load
1;
