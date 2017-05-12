###########################################################
# A Perl package for showing/modifying JPEG (meta)data.   #
# Copyright (C) 2004,2005,2006 Stefano Bettelli           #
# See the COPYING and LICENSE files for license terms.    #
###########################################################
#use Image::MetaData::JPEG::data::Tables qw();
no  integer;
use strict;
use warnings;

###########################################################
# This method parses an APP12 segment; this segment was   #
# used around 1998 by at least Olympus, Agfa and Epson    #
# as a non standard replacement for EXIF. Information is  #
# semi-readeable (mainly ascii text), but the format is   #
# undocument (let me know if you have any documentation!) #
#=========================================================#
# From the few examples I was able to find, my interpre-  #
# tation of the APP12 format is the following:            #
#---------------------------------------------------------#
#  1 line         identification (maker info?)            #
#----- multiple times ------------------------------------#
#  1 line         group (a string in square brackets)     #
# multiple lines  records (key-value separated by '=')    #
#----- multiple times ------------------------------------#
#  characters     group (a string in square brackets)     #
#  characters     unintelligible data                     #
#=========================================================#
# Well, this description looks a mess, I know. It means   #
# that after the identification line, there is some plain #
# ascii information (divided in groups, each group starts #
# with a line like "[picture info]", each key-value pair  #
# span one line) followed by groups containing binary     #
# data (so that splitting on line ends does not work!).   #
# Line terminations are marked by '\r\n' = 0x0d0a.        #
#=========================================================#
# Ref: ... ???                                            #
###########################################################
sub parse_app12 {
    my ($this) = @_;
    # compile once and for all the following regular expression,
    # which captures a [groupname]; the name can contain alphanumeric
    # characters, underscores and spaces (this is a guess ...)
    my $groupname = qr/^\[([ \w]*)\]/;
    # search the string "[user]" in the data area; it seems to
    # separate the ascii data area from the binary data area.
    # If the string is not there ($limit = -1), convert this value
    # to the past-the-end character.
    my $limit = index $this->data(0, $this->size()), "[user]";
    $limit = $this->size() if $limit == -1;
    # get all segment data up to the $limit and split in lines
    # (each line is terminated by carriage-return + line-feed)
    my @lines = split /\r\n/, $this->data(0, $limit);
    # extract the first line out of @lines, because it must be
    # treated differently. It seems that this line contains some
    # null characters, but I don't want to split it further ...
    my $preamble = shift @lines;
    $this->store_record('MakerInfo', $ASCII, \ $preamble, length $preamble);
    # each group will be written to a different subdirectory
    my $dirref = undef;
    # for each line in the ascii data area, except the first ...
    for (@lines) {
	# if the line is like "[groupname]", extract the group name
	# from the square brackets and create a new subdirectory
	if (/^$groupname$/) { $dirref = $this->provide_subdirectory($1); } 
	# otherwise, split the line on "="; on the left we find the 
	# tag name, on the right the ascii value(s). Store, in the
	# appropriate subdirectory, a non-numeric record.
	else { my ($tag, $vals) = split /=/, $_;
	       $this->store_record($dirref,$tag,$ASCII,\$vals,length $vals); }
    }
    # it's time to take care of the binary data area. We can't rely
    # on line terminations here, so a different strategy is necessary.
    # First, the remainig of the data area is copied in a variable ...
    my $binary = $this->data($limit, $this->size() - $limit);
    # ... then this variable is slowly consumed
    while (0 != length $binary) {
	# match the [groupname] string. It must be at the beginning
	# of $$binary_ref, otherwise something is going wrong ...
	$binary =~ /$groupname/;
	$this->die('Error while decoding binary data') if $-[0] != 0;
	# the subgroup matches the groupname (without the square
	# brackets); assume the rest, up to the end, is the value
	my $tag = $1; 
	my $val = substr $binary, $+[0];
	# but if we find another [groupname],
	# we change our mind on where the value ends
	$val = substr($val, 0, $-[0]) if $val =~ /$groupname/;
	# take out the group name and the value from binary, then
	# save them in a non-numeric record as undefined bytes (add
	# 2 to the length sum, this counts the two square brackets)
	$binary = substr($binary, length($tag) + length($val) + 2);
	$this->store_record($tag, $UNDEF, \$val, length $val);
    }
}

# successful load
1;
