###########################################################
# A Perl package for showing/modifying JPEG (meta)data.   #
# Copyright (C) 2004,2005,2006 Stefano Bettelli           #
# See the COPYING and LICENSE files for license terms.    #
###########################################################
package Image::MetaData::JPEG;
no  integer;
use strict;
use warnings;

###########################################################
# This method is for display/debug pourpouse. It returns  #
# a string describing the details of the structure of the #
# JPEG file linked to the current object. It can ask      #
# details to sub-objects.                                 #
###########################################################
sub get_description {
    my ($this) = @_;
    # prepare the string to be returned and store
    # a bar and the associated filename
    my $description = "Original JPEG file: $this->{filename}\n";
    # Print the image size
    $description .= sprintf "(%dx%d)\n", $this->get_dimensions();
    # Loop over all segments (use the order of the array)
    $description .= $_->get_description() foreach @{$this->{segments}};
    # return the string which was cooked up
    return $description;
}

###########################################################
# This method returns the image size from two specific    #
# record values in the SOF segment. The return value is   #
# (x-dimension, y- dimension). If there is no SOF segment #
# (or more than one), the return value is (0,0). In this  #
# case one should investigate, because this is not normal.#
#=========================================================#
# Ref: .... ?                                             #
###########################################################
sub get_dimensions {
    my ($this) = @_;
    # find the start of frame segments
    my @sofs = $this->get_segments("SOF");
    # if there is more than one such segment, there is something
    # wrong. In this case it is better to return (0,0) and debug.
    return (0,0) if (scalar @sofs) != 1;
    # same if there is an error in the segment
    my $segment = $sofs[0];
    return (0,0) if $segment->{error};
    # search the relevant records and get their values: if they are
    # not there, we get undef, which we promptly transform into zero
    my $xdim = $segment->search_record_value('MaxSamplesPerLine') || 0;
    my $ydim = $segment->search_record_value('MaxLineNumber')     || 0;
    # return dimension values
    return ( $xdim, $ydim );
}

###########################################################
# This method returns a reference to a hash with a plain  #
# translation of the content of the first interesting     #
# APP0 segment (this is the first 'JFXX' APP0 segment,    #
# if present, the first 'JFIF' APP0 segment otherwise).   #
# Segments with errors are excluded. An empty hash means  #
# that no valid APP0 segment is present.                  #
# See Segment::parse_app0 for further details.            #
#=========================================================#
#     JFIF          JFXX          JFXX          JFXX      #
#    (basic)    (RGB 1 byte)  (RGB 3 bytes)    (JPEG)     #
#  -----------  ------------  -------------  -----------  #
#   Identifier   Identifier    Identifier    Identifier   #
#  MajorVersion ExtensionCode ExtensionCode ExtensionCode #
#  MinorVersion  XThumbnail    XThumbnail   JPEGThumbnail #
#     Units      YThumbnail    YThumbnail                 #
#    XDensity   ColorPalette 3BytesThumbnail              #
#    YDensity  1ByteThumbnail                             #
#   XThumbnail                                            #
#   YThumbnail                                            #
#  ThumbnailData                                          #
###########################################################
sub get_app0_data {
    my ($this) = @_;
    # find all APP0 segments, excluding segments with errors
    my @app0s = grep { ! $_->{error} } $this->get_segments("APP0");
    # select extended JFIF segments (the identifier contains JFXX)
    my @jfxxs = grep { my $id = $_->search_record_value('Identifier');
		       defined $id && $id =~ /JFXX/ } @app0s;
    # select a segment (try JFXX, then plain APP0, otherwise undef)
    my $segment = @jfxxs ? $jfxxs[0] : (@app0s ? $app0s[0] : undef);
    # prepare a hash with the records in the APP0 segment
    my %data = map { $_->{key} => $_->get_value() } @{$segment->{records}};
    # return a reference to the filled hash
    return \ %data;
}

# successful package load
1;
