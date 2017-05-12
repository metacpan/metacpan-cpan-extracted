###########################################################
# A Perl package for showing/modifying JPEG (meta)data.   #
# Copyright (C) 2004,2005,2006 Stefano Bettelli           #
# See the COPYING and LICENSE files for license terms.    #
###########################################################
use Image::MetaData::JPEG::data::Tables qw();
no  integer;
use strict;
use warnings;

###########################################################
# This method parses a Quantization Table (DQT) segment,  #
# which can specify one or more quantization tables. The  #
# structure is the following:                             #
#------ multiple times -----------------------------------#
#  4 bits   quantization table element precision          #
#  4 bits   quantization table destination identifier     #
# 64 times  quantization table elements                   #
#---------------------------------------------------------#
# Quantization table elements span either 1 or 2 bytes,   #
# depending on the precision (0 -> 1 byte, 1 -> 2 bytes). #
###########################################################
# Ref: "Digital compression and coding of continuous-tone #
#       still images: requirements and guidelines", CCITT #
#       recommendation T.81, 09/1992, pag. 39-40.         #
###########################################################
sub parse_dqt {
    my ($this) = @_;
    my $offset = 0;
    # there can be multiple quantization tables
    while ($offset < $this->size()) {
	# read a byte, containing the quantization table element
	# precision (first nibble) and the destination identifier.
	my $precision = $this->store_record
	    ('PrecisionAndIdentifier', $NIBBLES, $offset)->get_value(0);
        # Then decode the first four bits to get the size
	# of the table (64 bytes or 128 bytes).
	my $element_size = ($precision == 0) ? 1 : 2;
	my $table_size = $element_size * 64;
	# check that there is enough data
	$this->test_size($offset + $table_size);
	# read the table in (always 64 elements, but bytes or shorts)
	$this->store_record('QuantizationTable',
			    $element_size == 1 ? $BYTE : $SHORT, $offset, 64);
    }
}

###########################################################
# This method parses a Huffman table (DHT) segment, which #
# can specify one or more Huffman tables. The structure   #
# is the following:                                       #
#------ multiple times -----------------------------------#
#  4 bits   table class                                   #
#  4 bits   destination identifier                        #
# 16 bytes  number of Huffman codes of given length for   #
#           each of the 16 possible lengths.              #
#  .....    values associated with each Huffman code;     #
#           each value needs a byte, and the total number #
#           of values is the sum of the previous 16 bytes #
###########################################################
# Ref: "Digital compression and coding of continuous-tone #
#       still images: requirements and guidelines", CCITT #
#       recommendation T.81, 09/1992, pag. 40-41.         #
###########################################################
sub parse_dht {
    my ($this) = @_;
    my $offset = 0;
    my $huffman_codes = 16;
    # there can be multiple Huffman tables
    while ($offset < $this->size()) {
	# read a byte, containing the table class and destination
	$this->store_record('ClassAndIdentifier', $NIBBLES, $offset);
	# read the number of Huffman codes of length i
	# (i in 1..16) as a single multi-valued record,
	# then extract the sum of all these values
	my $huffman_size = $this->store_record
	    ('CodeLengths', $BYTE, $offset, $huffman_codes)->get_value();
	# extract of values associated with all Huffman codes
	# as a single multi-valued record
	$this->store_record('CodeData', $BYTE, $offset, $huffman_size);
    }
    # be sure there is no size mismatch
    $this->test_size($offset);
}

###########################################################
# This method parses an Arithmetic Coding table (DAC)     #
# segment, which can specify one or more arithmetic co-   #
# ding conditioning tables (replacing the default one set #
# up by the SOI segment). The structure is the following: #
#------ multiple times -----------------------------------#
#  4 bits   table class                                   #
#  4 bits   destination identifier                        #
#  1 byte   conditioning table value                      #
#---------------------------------------------------------#
# It seems the arithmetic coding is covered by three pa-  #
# tents by three different companies; since its gain over #
# the Huffman coding scheme is only 5-10%, in practise    #
# you will never find this segment in your lifetime.      #
###########################################################
# Ref: "Digital compression and coding of continuous-tone #
#       still images: requirements and guidelines", CCITT #
#       recommendation T.81, 09/1992, sec.B.2.43, pag.42. #
###########################################################
sub parse_dac {
    my ($this) = @_;
    my $offset = 0;
    # there can be multiple Huffman tables
    while ($offset < $this->size()) {
	# read a byte, containing the table class and destination,
	# then another byte with the conditioning table value
	$this->store_record('ClassAndIdentifier'    , $NIBBLES, $offset);
	$this->store_record('ConditioningTableValue', $BYTE,    $offset);
    }
    # be sure there is no size mismatch
    $this->test_size($offset);
}

###########################################################
# This method parses an EXPansion segment (EXP), which    #
# specifies horizontal and vertical expansion parameters  #
# for the next frame. The structure is the following:     #
#------ multiple times -----------------------------------#
#  4 bits   horizontal expansion coefficient              #
#  4 bits   vertical expansion coefficient                #
###########################################################
# Ref: "Digital compression and coding of continuous-tone #
#       still images: requirements and guidelines", CCITT #
#       recommendation T.81, 09/1992, sec.B.3.3, pag.46.  #
###########################################################
sub parse_exp {
    my ($this) = @_;
    # this segments contains exactly one data byte
    $this->test_size(-1);
    # read a byte, containing both expansion coefficients
    $this->store_record('ExpansionCoefficients', $NIBBLES, 0);
}

###########################################################
# This method parses a Define Num of Lines (DNL) segment. #
# Such a segment provides a mechanism for defining or re- #
# defining the number of lines in the frame at the end of #
# the first scan. This marker segment is mandatory if the #
# number of lines specified in the frame header has the   #
# value zero. The structure is the following:             #
#---------------------------------------------------------#
#  2 bytes  number of lines in the frame.                 #
###########################################################
# Ref: "Digital compression and coding of continuous-tone #
#       still images: requirements and guidelines", CCITT #
#       recommendation T.81, 09/1992, sec.B.2.5, pag.45.  #
###########################################################
sub parse_dnl {
    my ($this) = @_;
    # exactly two bytes, plese
    $this->test_size(-2);
    # read the number of lines
    $this->store_record('NumberOfLines', $SHORT, 0);
}

###########################################################
# This method parses a Define Restart Interval (DRI) seg- #
# ment. There is only one parameter in this segment, and  #
# it specifies the number of MCU (minimum coding units)   #
# in the restart interval; a value equal to zero disables #
# the mechanism. The structure is the following:          #
#---------------------------------------------------------#
#  2 bytes  number of MCU in the restart interval.        #
###########################################################
# Ref: "Digital compression and coding of continuous-tone #
#       still images: requirements and guidelines", CCITT #
#       recommendation T.81, 09/1992, sec.B.2.4.4, pag.43.#
###########################################################
sub parse_dri {
    my ($this) = @_;
    # exactly two bytes, plese
    $this->test_size(-2);
    # read the number of MCU in the interval
    $this->store_record('NumMCU_inInterval', $SHORT, 0);
}

###########################################################
# This method parses a Start Of Frame (SOF) segment (but  #
# also a DHP segment, see note at the end). Such a seg-   #
# ment specifies the source image characteristics, the    #
# components in the frame, and the sampling factors for   #
# each components, and specifies the destinations from    #
# which the quantised tables to be used with each compo-  #
# nent are retrieved. The structure is:                   #
#---------------------------------------------------------#
#  1 byte   sample precision (in bits)                    #
#  2 bytes  maximum number of lines in source image       #
#  2 bytes  max. num. of samples per line in source image #
#  1 byte   number N of image components in frame         #
#------ N times ------------------------------------------#
#  1 byte   component identifier                          #
#  4 bits   horizontal sampling factor                    #
#  4 bits   vertical sampling factor                      #
#  1 byte   quantisation table destination selector       #
#=========================================================#
# A DHP segment defines the image components, size and    #
# sampling factors for the completed hierarchical sequence#
# of frames. It precedes the first frame, and its struc-  #
# ture is identical to the frame header syntax, except    #
# that the quantisation table destination selector is 0.  #
#=========================================================#
# The meaning of the different SOF segments is this:      #
#                                                         #
#   / Baseline \     (extended)   Progressive   Lossless  #
#   \  SOF_0   /     sequential                           #
#                                                         #
# (normal)             SOF_1         SOF_2        SOF_3   #
# Differential         SOF_5         SOF_6        SOF_7   #
# Arithmetic coding    SOF_9         SOF_A        SOF_B   #
# Diff., arithm.cod.   SOF_D         SOF_E        SOF_F   #
#=========================================================#
# Ref: "Digital compression and coding of continuous-tone #
#       still images: requirements and guidelines", CCITT #
#       recommendation T.81, 09/1992, sec.B.2.2, pag.35-36#
#       (DHP --> sec. B.3.2, pag. 46).                    #
###########################################################
sub parse_sof {
    my ($this) = @_;
    my $offset = 0;
    my $minimum_size = 6;
    # at least six bytes, plese
    $this->test_size($minimum_size);
    # read the first four values (the last value is
    # the number of image components in this frame)
    $this->store_record('SamplePrecision'  , $BYTE , $offset);
    $this->store_record('MaxLineNumber'    , $SHORT, $offset);
    $this->store_record('MaxSamplesPerLine', $SHORT, $offset);
    my $components = $this->store_record
	('ImageComponents', $BYTE , $offset)->get_value();
    # the number of image components allows us to calculate
    # the size of the remaining part of the segment
    $this->test_size($offset + 3*$components, "in component block");
    # scan all the frame component
    for (1..$components) {
	# three values per component
	$this->store_record('ComponentIdentifier'  , $BYTE   , $offset);
	$this->store_record('SamplingFactors'      , $NIBBLES, $offset);
	$this->store_record('QTDestinationSelector', $BYTE   , $offset);
    }
}

###########################################################
# This method parses the Start Of Scan (SOS) segment: it  #
# gives various scan-related parameters and introduces    #
# the JPEG raw data. The structure is the following:      #
#---------------------------------------------------------#
#  1 byte   number n of components in scan                #
#------------ n times ----------------------------------- #
#  1 byte   scan component selector                       #
#  4 bits   DC entropy coding table destination selector  #
#  4 bits   AC entropy coding table destination selector  #
#---------------------------------------------------------#
#  1 byte   start of spectral or prediction selection     #
#  1 byte   end of spectral selection                     #
#  2 nibbles Successive approximation bit position        #
###########################################################
# Ref: "Digital compression and coding of continuous-tone #
#       still images: requirements and guidelines", CCITT #
#       recommendation T.81, 09/1992, pag. 37-38.         #
###########################################################
sub parse_sos {
    my ($this) = @_;
    my $offset = 0;
    # read the number of components in the scan and calculate
    # the length of this segment; then, compare with what we
    # have in reality and produce an error if they differ
    my $components = $this->store_record
	('ScanComponents', $BYTE, $offset)->get_value();
    $this->test_size(-(1 + $components * 2 + 3));
    # Read two bytes for each component. The first byte is the
    # scan component selector (as numbered in the frame header);
    # the second byte contains the DC/AC entropy coding table
    # destination selector (a nibble each).
    for (1..$components) {
	$this->store_record('ComponentSelector', $BYTE,    $offset);
	$this->store_record('EntropySelector'  , $NIBBLES, $offset); }
    # the meaning of the last three bytes is the following:
    # 1) Start of spectral or prediction selection
    # 2) End of spectral selection
    # 3) Successive approximation bit position (2 nibbles)
    $this->store_record('SpectralSelectionStart'     , $BYTE,    $offset);
    $this->store_record('SpectralSelectionEnd'       , $BYTE,    $offset);
    $this->store_record('SuccessiveApproxBitPosition', $NIBBLES, $offset);
}

# successful load
1;
