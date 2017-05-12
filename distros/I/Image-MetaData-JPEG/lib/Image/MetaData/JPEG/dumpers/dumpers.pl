###########################################################
# A Perl package for showing/modifying JPEG (meta)data.   #
# Copyright (C) 2004,2005,2006 Stefano Bettelli           #
# See the COPYING and LICENSE files for license terms.    #
###########################################################
package Image::MetaData::JPEG::Segment;
no  integer;
use strict;
use warnings;

###########################################################
# GENERAL NOTICE: in general, all methods included by     #
# this file correspond to methods in parsers.pl, i.e.,    #
# each dump_* method corresponds to parse_* (with the     #
# same *, I mean :-). See these methods for further       #
# details. Only non-trivial comments will be added here.  # 
###########################################################

###########################################################
# Dumping a comment block is very easy, because it con-   #
# tains only one plain ASCII record.                      #
###########################################################
sub dump_com {
    my ($this) = @_;
    # write the only record into the data area
    $this->set_data($this->search_record_value('Comment'));
    # return without errors
    return undef;
}

###########################################################
# Require all other segment-specific dumpers.             #
###########################################################
#require 'Image/MetaData/JPEG/dumpers/app0.pl';
require 'Image/MetaData/JPEG/dumpers/app1.pl';
#require 'Image/MetaData/JPEG/dumpers/app2.pl';
#require 'Image/MetaData/JPEG/dumpers/app3.pl';
#require 'Image/MetaData/JPEG/dumpers/app12.pl';
require 'Image/MetaData/JPEG/dumpers/app13.pl';
#require 'Image/MetaData/JPEG/dumpers/app14.pl';
#require 'Image/MetaData/JPEG/dumpers/image.pl';

# successful package load
1;
