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
# This routine is a generic segment parsers, which saves  #
# the first 30 bytes of the segment in a record, then     #
# generates an error to inhibit update(). In this way,    #
# the segment must be rewritten to disk unchanged, but    #
# the nature of the segment is at least hinted by the     #
# initial bytes (just for debugging ...).                 #
###########################################################
sub parse_unknown {
    my ($this) = @_;
    # save the first 30 bytes and translate non-printing characters
    my $bytes = 30;
    $this->store_record("First $bytes bytes ...", $ASCII, 0, $bytes);
    # generate an error
    $this->die('Unknown segment type');
}

###########################################################
# This method parses a COM segment. This is very simple   #
# since it is just one string.                            #
###########################################################
sub parse_com {
    my ($this) = @_;
    # save the whole comment as a single value
    $this->store_record('Comment', $ASCII, 0, $this->size());
}

###########################################################
# Require all other segment-specific parsers.             #
###########################################################
require 'Image/MetaData/JPEG/parsers/app0.pl';
require 'Image/MetaData/JPEG/parsers/app1.pl';
require 'Image/MetaData/JPEG/parsers/app2.pl';
require 'Image/MetaData/JPEG/parsers/app3.pl';
require 'Image/MetaData/JPEG/parsers/app12.pl';
require 'Image/MetaData/JPEG/parsers/app13.pl';
require 'Image/MetaData/JPEG/parsers/app14.pl';
require 'Image/MetaData/JPEG/parsers/image.pl';

# successful package load
1;
