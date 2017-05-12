###########################################################
# A Perl package for showing/modifying JPEG (meta)data.   #
# Copyright (C) 2004,2005,2006 Stefano Bettelli           #
# See the COPYING and LICENSE files for license terms.    #
###########################################################
use Image::MetaData::JPEG::data::Tables qw(:TagsAPP1_Exif :TagsAPP1_XMP);
no  integer;
use strict;
use warnings;

###########################################################
# Entry point for dumping an APP1 segment. It decides     #
# between Exif APP1 and XMP and then dispatches to the    #
# correct subroutine (the identifier is not yet written). #
###########################################################
sub dump_app1 {
    my ($this) = @_;
    # Look for the 'Identifier' record (which should always exist and
    # contain the EXIF tag), and for a 'Namespace' record (Adobe XMP)
    my $identif   = $this->search_record_value('Identifier');
    my $namespace = $this->search_record_value('Namespace');
    # If the 'Identifier' record exists and contains
    # the EXIF tag, this is a standard Exif segment
    if ($identif && $identif eq $APP1_EXIF_TAG) { $this->dump_app1_exif(); }
    # Otherwise, look for a 'Namespace' record; chances
    # are this is an Adobe XMP segment
    elsif ($namespace) { return 'Dumping XMP APP1 not implemented'; }
    # Otherwise, we have a problem
    else { return 'Segment dump not possible'; }
    # return without errors
    return undef;
}

require 'Image/MetaData/JPEG/dumpers/app1_exif.pl';
#require 'Image/MetaData/JPEG/dumpers/app1_xmp.pl';

# successful load
1;
