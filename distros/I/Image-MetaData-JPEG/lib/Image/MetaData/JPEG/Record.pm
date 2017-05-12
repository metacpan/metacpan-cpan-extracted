###########################################################
# A Perl package for showing/modifying JPEG (meta)data.   #
# Copyright (C) 2004,2005,2006 Stefano Bettelli           #
# See the COPYING and LICENSE files for license terms.    #
###########################################################
package Image::MetaData::JPEG::Record;
use Image::MetaData::JPEG::Backtrace;
use Image::MetaData::JPEG::data::Tables 
    qw(:Endianness :RecordTypes :RecordProps :Lookups);
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
	       ($message,"Fatal error" . $this->info(), $this);}
sub info { my ($this) = @_;
	   my $key  = (ref $this && $this->{key})  || '<no key>';
	   my $type = (ref $this && $this->{type}) || '<no type>';
	   return " [key $key] [type $type]"; }

###########################################################
# A regular expression matching a legal endianness value. #
###########################################################
my $ENDIANNESS_OK = qr/$BIG_ENDIAN|$LITTLE_ENDIAN/o;

###########################################################
# Constructor for a generic key - values pair for storing #
# properties to be found in JPEG segments. The key is     #
# either a numeric value (whose exact meaning depends on  #
# the segment type, and can be found by means of lookup   #
# tables), or a descriptive string. The values are to be  #
# found in the scalar pointed to by the data reference,   #
# and they come togheter with a value type; the meaning   #
# of the value type is taken by the APP1 type table, but  #
# this standard can be used also for the other segments   #
# (but it is not stored in the file on disk, exception    #
# made for some APP segments). The count must be given    #
# for fixed-length types. The enddianness must be given   #
# for numeric properties with more than 1 byte.           #
#=========================================================#
# The "values" are a sequence, so this field is a list;   #
# it stores $count elements for numeric records, and a    #
# single scalar for non-numeric ones ("count", in this    #
# case, corresponds to the size of $$dataref; if $count   #
# is undefined, no length test is performed on $$dataref).#
#=========================================================#
# Types are as follows:                                   #
#  0  NIBBLES    two 4-bit unsigned integers (private)    #
#  1  BYTE       An 8-bit unsigned integer                #
#  2  ASCII      A variable length ASCII string           #
#  3  SHORT      A 16-bit unsigned integer                #
#  4  LONG       A 32-bit unsigned integer                #
#  5  RATIONAL   Two LONGs (numerator and denominator)    #
#  6  SBYTE      An 8-bit signed integer                  #
#  7  UNDEFINED  A generic variable length string         #
#  8  SSHORT     A 16-bit signed integer                  #
#  9  SLONG      A 32-bit signed integer (2's complem.)   #
# 10  SRATIONAL  Two SLONGs (numerator and denominator)   #
# 11  FLOAT      A 32-bit float (a single float)          #
# 12  DOUBLE     A 64-bit float (a double float)          #
# 13  REFERENCE  A Perl list reference (internal)         #
#=========================================================#
# Added a new field, "extra", which can be used to store  #
# additional information one does not know where to put.  #
# (The need originated from APP13 record descriptions).   #
###########################################################
sub new {
    my ($pkg, $akey, $atype, $dataref, $count, $endian) = @_;
    # die immediately if $dataref is not a reference
    $pkg->die('Reference not found') unless ref $dataref;
    # create a Record object with some fields filled
    my $this  = bless {
	key     => $akey,
	type    => $atype,
	values  => [],
	extra   => undef,
    }, $pkg;
    # use big endian as default endianness
    $endian = $BIG_ENDIAN unless defined $endian;
    # get the actual length of the $$dataref scalar
    my $current  = length($$dataref);
    # estimate the right length of $data for numeric types
    # (remember that some types can return "no expectation", i.e. 0).
    my $expected = $pkg->get_size($atype, $count);
    # for variable-length records (those with $expected == 0), the length
    # test must be run against $count, so we update $expected here if
    # necessary (if $count was not given a value at call time, $expected
    # is set to $current and the length test will never fail).
    $expected = $count ? $count : $current if $expected == 0;
    # Throw an error if the supplied memory area is incorrectly sized
    $this->die("Incorrect size (expected $expected, found $current)")
	if ($current != $expected);
    # get a reference to the internal value list
    my $tokens = $this->{values};
    # read the type length (used only for integers and rationals)
    my $tlength = $JPEG_RECORD_TYPE_LENGTH[$this->{type}];
    # References, strings and undefined data can be immediately saved
    # (1 element). All integer types can be treated toghether, and
    # rationals can be treated as integer (halving the type length).
    my $cat = $this->get_category();
    push @$tokens,
        $cat =~ /S|p/ ? $$dataref :
	$cat eq 'I' ? $this->decode_integers($tlength  , $dataref, $endian) :
	$cat eq 'R' ? $this->decode_integers($tlength/2, $dataref, $endian) :
	$cat eq 'F' ? $this->decode_floating($tlength  , $dataref, $endian) :
	$this->die('Unknown category');
    # die if the token list is empty
    $this->die('Empty token list') if @$tokens == 0;
    # return the blessed reference
    return $this;
}

###########################################################
# Syntactic sugar for a type test. The two arguments are  #
# $this and the numeric type.                             #
###########################################################
sub is { return $_[1] == $_[0]{type}; }

###########################################################
# This method returns a character describing the category #
# which the type of the current record belongs to.        #
# There are currently only five categories:               #
# references  : 'p' -> Perl references (internal)         #
# integer     : 'I' -> NIBBLES, (S)BYTE, (S)SHORT,(S)LONG #
# string-like : 'S' -> ASCII, UNDEF                       #
# fractional  : 'R' -> RATIONAL, SRATIONAL                #
# float.-point: 'F' -> FLOAT, DOUBLE                      #
# The method is sufficiently clear to use $_[0] instead   #
# of $this (is it a speedup ?)                            #
###########################################################
sub get_category { return $JPEG_RECORD_TYPE_CATEGORY[$_[0]{type}]; }

###########################################################
# This method returns true or false depending on the      #
# record type being a signed integer or not (i.e. being   #
# SBYTE, SSHORT, SLONG or SRATIONAL). The method is       #
# sufficiently simple to use $_[0] instead of $this.      #
###########################################################
sub is_signed { return $JPEG_RECORD_TYPE_SIGN[$_[0]{type}] eq 'Y'; }

###########################################################
# This method calculates a record memory footprint; it    #
# needs the record type and the record count. This method #
# is class static (it can be called without an underlying #
# object), so it cannot use $this. $count defaults to 1.  #
# Remember that a type length of zero means that size     #
# should not be tested (this comes from TYPE_LENGHT = 0). #
###########################################################
sub get_size {
    my ($this, $type, $count) = @_;
    # if count is unspecified, set it to 1
    $count = 1 unless defined $count;
    # die if the type is unknown or undefined
    $this->die('Undefined record type') unless defined $type;
    $this->die("Unknown record type ($type)")
	if $type < 0 || $type > $#JPEG_RECORD_TYPE_LENGTH;
    # return the type length times $count
    return $JPEG_RECORD_TYPE_LENGTH[$type] * $count;
}

###########################################################
# This class static method receives a number of Record    #
# features (key, type and count) and a list of values,    #
# and tries to build a Record with that type and count    #
# containing those values. On success, it returns the     #
# record reference, on failure it returns undef.          #
# ------------------------------------------------------- #
# Floating point values are matched to six decimal digits #
###########################################################
sub check_consistency {
    my ($pkg, $key, $type, $count, $tokens) = @_;
    # create a dummy Record, the "fix" its type and its value list
    my $record = new Image::MetaData::JPEG::Record($key, $ASCII, \ "");
    @$record{'type', 'values'} = ($type, $tokens);
    # try to get back the record properties; return undef if it fails
    (undef, undef, my $new_count, my $dataref) = eval { $record->get() };
    return undef unless defined $dataref;
    # if $count was previously undefined, listen to the Record encoder
    $count = $new_count unless defined $count;
    # if counts are already different, there is no hope (this
    # can happen if $count was faulty: we haven't used it sofar).
    return undef if $count != $new_count;
    # build the real record by re-parsing the data reference; in my
    # opinion this should never fail, so I don't check the result.
    # Does this provide more chances to find a bug?
    $record = new Image::MetaData::JPEG::Record($key, $type, $dataref, $count);
    # return undef if the number of values does not match
    my $new_tokens = $record->{values};
    return undef unless scalar @$tokens == scalar @$new_tokens;
    # the new record can however have a value list different from
    # what we hope, since some data types could wrap. So we now
    # compare the value lists and return undef if they differ.
    for (0..$#$tokens) {
	return undef if ($record->get_category() eq 'F') ?
	    # due to the nature of floating point values, the comparison
	    # is limited to six decimal digits (the new token has a precision
	    # of 23 or 52 binary digits, while the old one is just a string)
	    sprintf("%.6g",$$new_tokens[$_]) ne sprintf("%.6g",$$tokens[$_]) :
	    # for all other types, compare the plain values
	    $$new_tokens[$_] ne $$tokens[$_]; }
    # if you get here, everything is ok: return the record reference
    return $record;
}

###########################################################
# This method returns a particular value in the value     #
# list, its index being the only argument. If the index   #
# is undefined (not supplied), the sum of all values is   #
# returned. The index is checked for out-of-bound errors. #
#=========================================================#
# For string-like records, "sum" -> "concatenation".      #
###########################################################
sub get_value {
    my ($this, $index) = @_;
    # get a reference to the value list
    my $values = $this->{values};
    # access a single value if an index is defined or
    # there is only one value (follow to sum otherwise)
    goto VALUE_INDEX if defined $index || @$values == 1;
  VALUE_SUM:
    return ($this->get_category() eq 'S') ?
	# perform concatenation for string-like values
	join "", @$values :
	# perform addition for numeric values
	eval (join "+", @$values);
  VALUE_INDEX:
    # $index defaults to zero
    $index = 0 unless defined $index;
    # get the last legal index
    my $last_index = $#$values;
    # check that $index is legal, throw an exception otherwise
    $this->die("Out-of-bound index ($index > $last_index)") 
	if $index > $last_index;
    # return the desired value
    return $$values[$index];
}

###########################################################
# This method sets a particular value in the value list.  #
# If the index is undefined (not supplied), the first     #
# (0th) value is set. The index is check for out-of-bound #
# errors. This method is dangerous: call only internally. #
###########################################################
sub set_value {
    my ($this, $new_value, $index) = @_;
    # get a reference to the value list
    my $values = $this->{values};
    # set the first value if index is defined
    $index = 0 unless defined $index;
    # check out-of-bound condition
    my $last_index = $#$values;
    $this->die("Out-of-bound index ($index > $last_index)")
	if $index > $last_index;
    # set the value
    $$values[$index] = $new_value;
}

###########################################################
# These private functions take signed/unsigned integers   #
# and return their unsigned/signed version; the type      #
# length in bytes must also be specified. $_[0] is the    #
# original value, $_[1] is the type length. $msb[$n] is   #
# an unsigned integer with the 8*$n-th bit turned up.     #
# There is also a function for converting binary data as  #
# a string into a big-endian number (iteratively) and a   #
# function for interchanging bytes with nibble pairs.     #
###########################################################
{ my @msb = map { 2**(8*$_ - 1) } 0..20;
  sub to_signed   { ($_[0] >= $msb[$_[1]]) ? ($_[0] - 2*$msb[$_[1]]) : $_[0] }
  sub to_unsigned { ($_[0] < 0) ? ($_[0] + 2*$msb[$_[1]]) : $_[0] }
  sub to_number   { my $v=0; for (unpack "C*", $_[0]) { ($v<<=8) += $_; } $v }
  sub to_nibbles  { map { chr(vec($_[0], $_, 4)) } reverse (0..1) }
  sub to_byte     { my $b="x"; vec($b,$_^1,4) = ord($_[$_]) for (0..1) ; $b }
}

###########################################################
# This method decodes a sequence of 8$n-bit integers, and #
# correctly takes into account signedness and endianness. #
# The data size must be validated in advance: in this     #
# routine it must be a multiple of the type size ($n).    #
#=========================================================#
# NIBBLES are treated apart. A "nibble record" is indeed  #
# a pair of 4-bit values, so the type length is 1, but    #
# each element must enter two values into @tokens. They   #
# are always big-endian and unsigned.                     #
#=========================================================#
# Don't use shift operators, which are a bit too tricky.. #
###########################################################
sub decode_integers {
    my ($this, $n, $dataref, $endian) = @_;
    # safety check on endianness
    $this->die('Unknown endianness') unless $endian =~ $ENDIANNESS_OK;
    # prepare the list of raw tokens
    my @tokens = unpack "a$n" x (length($$dataref)/$n), $$dataref;
    # correct the tokens for endianness if necessary
    @tokens = map { scalar reverse } @tokens if $endian eq $LITTLE_ENDIAN;
    # rework the raw token list for nibbles.
    @tokens = map { to_nibbles($_) } @tokens if $this->is($NIBBLES);
    # convert to 1-byte digits and concatenate them (assuming big-endian)
    @tokens = map { to_number($_) } @tokens;
    # correction for signedness.
    @tokens = map { to_signed($_, $n) } @tokens if $this->is_signed();
    # return the token list
    return @tokens;
}

###########################################################
# This method encodes the content of $this->{values} into #
# a sequence of 8$n-bit integers, correctly taking into   #
# account signedness and endianness. The return value is  #
# a reference to the encoded scalar, ready to be written  #
# to disk. See decode_integers() for further details.     #
###########################################################
sub encode_integers {
    my ($this, $n, $endian) = @_;
    # safety check on endianness
    $this->die('Unknown endianness') unless $endian =~ $ENDIANNESS_OK;
    # copy the value list (the original should not be touched)
    my @tokens = @{$this->{values}};
    # correction for signedness
    @tokens = map { to_unsigned($_, $n) } @tokens if $this->is_signed();
    # convert the number into 1-byte digits (assuming big-endian)
    @tokens = map { my $enc = ""; vec($enc, 0, 8*$n) = $_; $enc } @tokens;
    # reconstruct the raw token list for nibbles.
    @tokens = map { to_byte($tokens[2*$_], $tokens[2*$_+1]) } 0..(@tokens)/2-1
	if $this->is($NIBBLES);
    # correct the tokens for endianness if necessary
    @tokens = map { scalar reverse } @tokens if $endian eq $LITTLE_ENDIAN;
    # reconstruct a string from the list of raw tokens
    my $data = pack "a$n" x (scalar @tokens), @tokens;
    # return a reference to the reconstructed string
    return \ $data;
}

###########################################################
# This method decodes a data area containing a sequence   #
# of floating point values, correctly taking into account #
# the endianness. The type size $n can therefore be only  #
# 4, 8 or 12 (but you will not be able to store extended  #
# precision numbers unless your system provides support   #
# for them [a Cray?]). The data size must be validated in #
# advance: here it must be a multiple of the type size.   #
###########################################################
sub decode_floating {
    my ($this, $n, $dataref, $endian) = @_;
    # safety check on endianness
    $this->die('Unknown endianness') unless $endian =~ $ENDIANNESS_OK;
    # prepare the list of raw tokens
    my @tokens = unpack "a$n" x (length($$dataref)/$n), $$dataref;
    # correct the tokens for endianness if necessary (to native endianness)
    @tokens = map { scalar reverse } @tokens if $endian ne $NATIVE_ENDIANNESS;
    # select the correct conversion format (single/double/extended)
    my $format = ('f', 'd', 'D')[$n/4 - 1];
    # loop over all tokens (numbers) and extract them
    @tokens = map { unpack $format, $_ } @tokens;
    # return the token list
    return @tokens;
}

###########################################################
# This method encodes the content of $this->{values} into #
# a sequence of floating point numbers, correctly taking  #
# into account the endianness. The returned value is a    #
# reference to the encoded scalar, ready to be written to #
# disk. See decode_floating() for further details.        #
###########################################################
sub encode_floating {
    my ($this, $n, $endian) = @_;
    # safety check on endianness
    $this->die('Unknown endianness') unless $endian =~ $ENDIANNESS_OK;
    # get a simpler reference to the value list
    my @tokens = @{$this->{values}};
    # select the correct conversion format (single/double/extended)
    my $format = ('f', 'd', 'D')[$n/4 - 1];
    # loop over all tokens (floating point numbers)
    @tokens = map { pack $format, $_ } @tokens;
    # correct the tokens for endianness if necessary (from native endianness)
    @tokens = map { scalar reverse } @tokens if $endian ne $NATIVE_ENDIANNESS;
    # reconstruct a string from the list of raw tokens
    my $data = join '', @tokens;
    # return a reference to the reconstructed string
    return \ $data;
}

###########################################################
# This method returns the content of the record: in list  #
# context it returns (key, type, count, data_reference).  #
# The reference points to a packed scalar, ready to be    #
# written to disk. In scalar context, it returns "data",  #
# i.e. the dereferentiated data_reference. This is tricky #
# (but handy for other routines). The endianness argument #
# defaults to $BIG_ENDIAN. See ctor for further details.  #
###########################################################
sub get {
    my ($this, $endian) = @_;
    # use big endian as default endianness
    $endian = $BIG_ENDIAN unless defined $endian;
    # get the record type and a reference to the internal value list
    my $type     = $this->{type};
    my $tokens   = $this->{values};
    my $category = $this->get_category();
    # read the type length (only used for integers and rationals)
    my $tlength  = $JPEG_RECORD_TYPE_LENGTH[$type];
    # References, strings and undefined data contain a single value
    # (to be taken a reference at). All integer types can be treated
    # toghether, and rationals can be treated as integer (halving the
    # type length). Floating points still to be coded.
    my $dataref =
	$category =~ /S|p/ ? \ $$tokens[0] :
	$category eq 'I' ? $this->encode_integers($tlength  , $endian) :
	$category eq 'R' ? $this->encode_integers($tlength/2, $endian) :
	$category eq 'F' ? $this->encode_floating($tlength  , $endian) :
	$this->die('Unknown category');
    # calculate the "count" (the number of elements for numeric types
    # and the length of $$dataref for references, strings, undefined)
    my $count = length($$dataref) / ( $category =~ /S|p/ ? 1 : $tlength );
    # return the result, depending on the context
    wantarray ? ($this->{key}, $type, $count, $dataref) : $$dataref;
}

###########################################################
# This routine reworks $ASCII and $UNDEF record values    #
# before displaying them. In particular, unreasonably     #
# long strings are trimmed and non-printing characters    #
# are replaced with their hexadecimal representation.     #
# Strings are then enclosed between delimiters, and null- #
# terminated ones can have their last character chopped   #
# off (but a dot is added after the closing delimiter).   #
# Remember to copy the string to avoid side-effects!      #
# ------------------------------------------------------- #
# $_[0] --> this contains the string to be modified.      #
# $_[1] --> this contains the string delimiter (" or ')   #
# $_[2] --> true if the last null char is to be replaced  #
###########################################################
sub string_manipulator {
    # max length of the part of the string we want to display
    # (after conversion of non-printing chars to hex repr.)
    my $maxlen = 40;
    # running variables
    my ($left, $string) = (length $_[0], '');
    my ($delim, $dropnull) = @_[1,2];
    # loop over all characters in the string
    for (0..(length($_[0])-1)) {
	# get a copy of the current character
	my $token = substr($_[0], $_, 1);
	# translate it to a string if it is non-printing
	$token =~ s/[\000-\037\177-\377]/sprintf "\\%02x",ord($&)/e;
	# stop here if the overall string becomes too long
	last if length($token) + length($string) > $maxlen;
	# update running variables
	--$left; $string .= $token; }
    # transform the terminating null character into a dot if the
    # string does not start with a slash, then put delimiters
    # around the string (the dot remains outside, however).
    $string = "${delim}$string${delim}";
    $string =~ s/^(.*)\\00${delim}$/$1${delim}\./ if $dropnull;
    # print the reworked string (if the string was shortened,
    # add a notice to the end and use a fixed length field)
    sprintf($left ? '%-'.(3+$maxlen)."s($left more chars)" : '%-s', $string);
}

###########################################################
# This method returns a string describing the content of  #
# the record. The argument is a reference to an array of  #
# names, which are to be used as successive keys in a     #
# general hash keeping translations of numeric tags.      #
# No argument is needed if the key is already non-numeric.#
###########################################################
sub get_description {
    my ($this, $names) = @_;
    # some internal parameters
    my $maxlen = 25; my $max_tokens = 7;
    # try not to die every time if $names is undefined ...
    $names = [] unless defined $names;
    # assume that the key is a string (so, it is its own
    # description, and no numeric value is to be shown)
    my $descriptor = $this->{key};
    my $numerictag = undef;
    # however, if it is a number we need more work
    if ($descriptor =~ /^\d*$/) {
	# get the relevant hash for the description of this record
	my $section_hash = JPEG_lookup(@$names);
	# fix the numeric tag
	$numerictag = $descriptor;
        # extract a description string; if there is no entry in the
	# hash for this key, replace the descriptor with a sort of
	# error message (non-existent tags differ from undefined ones)
	$descriptor =
	    ! exists $$section_hash{$descriptor}  ? "?? Unknown record ??"  :
	    ! defined $$section_hash{$descriptor} ? "?? Nameless record ??" :
	    $$section_hash{$descriptor} }
    # calculate an appropriate tabbing
    my $tabbing = " \t" x (scalar @$names);
    # prepare the description (don't make it exceed $maxlen characters).
    $descriptor = substr($descriptor, 0, $maxlen/2)
	. "..." . substr($descriptor, - $maxlen/2 + 3)
	if length($descriptor) > $maxlen;
    # initialise the string to be returned at the end
    my $description = sprintf "%s[%${maxlen}s]", $tabbing, $descriptor;
    # show also the numeric tag for this record (if present)
    $description .= defined $numerictag ?
	sprintf "<0x%04x>", $numerictag : "<......>";
    # show the tag type as a string
    $description .= sprintf " = [%9s] ", $JPEG_RECORD_TYPE_NAME[$this->{type}];
    # show the "extra" field if present
    $description .= "<$this->{extra}>" if defined $this->{extra};
    # take a reference to the list of objects to process
    my $tokens = $this->{values};
    # we want to write at most $max_tokens tokens in the value list
    my $extra = $#$tokens - $max_tokens;
    my $token_limit = $extra > 0 ? $max_tokens : $#$tokens;
    # some auxiliary variables (depending only on the record type)
    my $intfs = $this->is_signed() ? '%d' : '%u';
    my $sep   = $this->is($ASCII)  ? '"'  : "'" ;
    my $text  = sub { string_manipulator($_[0], $sep, $this->is($ASCII)) };
    # integers, strings and floating points are written in sequence;
    # rationals must be written in pairs (use a flip-flop);
    # undefined values are written on a byte per byte basis.
    my $f = '/';
    foreach (@$tokens[0..$token_limit]) {
	# update the flip flop
	$f = $f eq ' ' ? '/' : ' ';
	# some auxiliary variables
	my $category = $this->get_category();
	# show something, depending on category and type
	$description .= 
	    $category eq 'p' ? sprintf ' --> 0x%06x', $_         :
	    $category eq 'S' ? sprintf '%s'         , &$text($_) :
	    $category eq 'I' ? sprintf ' '.$intfs   , $_         :
	    $category eq 'F' ? sprintf ' %g'        , $_         :
	    $category eq 'R' ? sprintf '%s'.$intfs  , $f, $_     :
	    $this->die('Unknown error condition'); }
    # terminate the line; remember to put a warning note if there were
    # more than $max_tokens element to display, then return the description
    $description .= " ... ($extra more values)" if $extra > 0;
    $description .= "\n";
    # return the descriptive string
    return $description;
}

# successful package load
1;
