package EBook::MOBI::Mhtml2Mobi;

our $VERSION = '0.72'; # VERSION (hook for Dist::Zilla::Plugin::OurPkgVersion)

# This file contains some example code, borrowed from MobiPerl.
# The code comes from the html2mobi file from MobiPerl.
# Thus this code has the same license than MobiPerl:

#    Copyright (C) 2011 Boris Daeppen <bod@perl-services.de>
#
#    ORIGINAL:
#    MobiPerl/EXTH.pm, Copyright (C) 2007 Tommy Persson, tpe@ida.liu.se
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

# This code creates a .mobi file for the Amazone Kindle eBook Reader
use strict;
use warnings;
use File::Basename;
use File::Spec;
use Carp;

# Use some project library
#use EBook::MOBI::Image; # this lib gets called from the fly
{
    package MockImage;

    sub new {
        return bless {}, shift
    }
    sub rescale_dimensions {
        print "EBook::MOBI::Image not loaded, rescale_dimensions command ignored\n"
    }
    sub debug_on {
        print "EBook::MOBI::Image not loaded, debug_on command ignored\n"
    }
    sub debug_off {
        print "EBook::MOBI::Image not loaded, debug_off command ignored\n"
    }
    sub _debug {
        print "EBook::MOBI::Image not loaded, _debug command ignored\n"
    }
}

# Use the library, downloaded from MobiPerl
use EBook::MOBI::MobiPerl::Palm::PDB;
use EBook::MOBI::MobiPerl::Palm::Doc;
use EBook::MOBI::MobiPerl::MobiHeader;
use EBook::MOBI::MobiPerl::Util;

# This values are set according to MobiPerl
use constant DOC_UNCOMPRESSED => scalar 1;
use constant DOC_COMPRESSED => scalar 2;
use constant DOC_RECSIZE => scalar 4096;

# Constructor of this class
sub new {
    my $self=shift;
    my $ref={};

    $ref->{picture_paths} = []; # containing all the pictures path
    $ref->{mobi_pic} = MockImage->new();

    bless($ref, $self);
    return $ref;
}

sub debug_on {
    my ($self, $ref_to_debug_sub) = @_; 

    $self->{ref_to_debug_sub} = $ref_to_debug_sub;
    
    &$ref_to_debug_sub('DEBUG mode on');
}

sub debug_off {
    my ($self) = @_; 

    if ($self->{ref_to_debug_sub}) {
        &{$self->{ref_to_debug_sub}}('DEBUG mode off');
        $self->{ref_to_debug_sub} = 0;

        $self->{mobi_pic}->debug_off();
    }   
}

# Internal debug method
sub _debug {
    my ($self,$msg) = @_; 

    if ($self->{ref_to_debug_sub}) {
        &{$self->{ref_to_debug_sub}}($msg);
    }   
}

# This method does the job!
# Give it some (mobi compatible) HTML and it creates a Mobi file for you
sub pack {
    my ($self,      # object
        $html,      # data to put in the mobi eBook
        $filename,  # filename (with path) of the desired eBook
        $author,    # author of the eBook
        $title,     # title of the eBook
        $codepage,   # codepage that eBook reader is to use when displaying text
        $header_opts, 
       ) = @_;

    # un-comment if you need to see all the HTML
    #print "\n--HTML--\n$html\n--HTML--\n";

    # Palm DOC Header
    # According to MobiPerl (html2mobi)
    my $mobi = EBook::MOBI::MobiPerl::Palm::Doc->new();
    $mobi->{attributes}{"resource"} = 0;
    $mobi->{attributes}{"ResDB"} = 0;
    $mobi->{"name"} = $title;
    $mobi->{"type"} = "BOOK";
    $mobi->{"creator"} = "MOBI";
    $mobi->{"version"} = 0;
    $mobi->{"uniqueIDseed"} = 28;
    $mobi->{'records'} = [];
    $mobi->{'resources'} = [];

    # Inside Palm DOC Header is the MOBI Header
    # According to MobiPerl (html2mobi)
    my $header = $mobi->append_Record();    
    my $version = DOC_COMPRESSED;
    $header->{'version'} = $version;
    $header->{'length'} = 0;
    $header->{'records'} = 0;
    $header->{'recsize'} = DOC_RECSIZE;

    # Large HTML text must be devided into chunks...
    # break the document into record-sized chunks.
    # According to MobiPerl (html2mobi)
    my $current_record_index = 1;
    for( my $i = 0; $i < length($html); $i += DOC_RECSIZE ) {

        # DEBUG: print the current record index
        $self->_debug(
            'Storing HTML in the mobi format at record '
            . $current_record_index
            );
        my $record = $mobi->append_Record;
        my $chunk = substr($html,$i,DOC_RECSIZE);
        $record->{'data'} =
            EBook::MOBI::MobiPerl::Palm::Doc::_compress_record
            ( $version, $chunk );
        $record->{'id'} = $current_record_index++;
        $header->{'records'} ++;
    }
    $header->{'length'} += length $html;
    $header->{'recsize'} = $header->{'length'}
        if $header->{'length'} < DOC_RECSIZE;

    # pack the Palm Doc  header
    # According to MobiPerl (html2mobi)
    $header->{'data'} = pack( 'n xx N n n N'      ,
                              $header->{'version'},
                              $header->{'length'} ,
                              $header->{'records'},
                              $header->{'recsize'},
                              0
                            );

    # Add MOBI header
    # According to MobiPerl (html2mobi)
    my $mh = new EBook::MOBI::MobiPerl::MobiHeader;
    $mh->set_title ($title);
    $mh->set_author ($author);
    $mh->set_codepage ($codepage);
    
    if($header_opts and ref($header_opts) eq 'HASH'){
     $mh->set_language($header_opts->{language}) if(exists $header_opts->{language});
    }
    
    $mh->set_image_record_index ($current_record_index);

    $header->{'data'} .= $mh->get_data ();

    # Add pictures into the binary mobi format.
    # Each picture gets its own record, so splitting into chunks.

    # Looking for pictures in the html data,
    # storing the path of the pics in $self->{picture_paths}
    $self->_gather_IMG_ref($html);

    if ( @{$self->{picture_paths}} ) {
        eval {
            require EBook::MOBI::Image;
            EBook::MOBI::Image->import();
            $self->{mobi_pic} = EBook::MOBI::Image->new();
        };  
        die "MODULE MISSING! Ebook contains images. Can only proceed if you install EBook::MOBI::Image\n$@" if $@;

        if ($self->{ref_to_debug_sub}) {
            $self->{mobi_pic}->debug_on($self->{ref_to_debug_sub});
        }
    }
    
    # add each pic to the mobi container
    foreach my $img_path (@{$self->{picture_paths}}) {

        # We pass the picture to this object, to ensure that
        # the picture size is fine for the mobi format.
        # Return-value migth be a new path, in case of resizing!
        $img_path = $self->{mobi_pic}->rescale_dimensions($img_path);
        
        # DEBUG: print info for each picture
        $self->_debug(
            'Storing picture in mobi format: '
            . "record_index: $current_record_index, image: $img_path");

        # According to MobiPerl (html2mobi)
        my $img = EBook::MOBI::MobiPerl::Palm::PDB->new_Record();
        $img->{"categori"} = 0;
        $img->{"attributes"}{"Dirty"} = 1;
        # increase counter, for the next picture to be added...
        $img->{"id"} = $current_record_index++;

        # read binary picture data
        my $data;
        my $buff;
        open(my $IMG, $img_path) or die "can't open file: $!";
        binmode($IMG);
        # That's how MobiPerl reads the data so we do it the same way
        while (read($IMG, $buff, 8 * 2**10)) {
            $data .= $buff;
        }
        close($IMG);
        $img->{"data"} = $data;

        # finally we append the image data to the record,
        # and repeat the loop
        $mobi->append_Record ($img);
    }

    # FINISH! Write the Mobi file (and pray that it's fine)
    $mobi->Write ($filename);
}

# Internal sub.
# It fetches all the paths from the IMG tags of a HTML string
sub _gather_IMG_ref {
    my ($self,$html) = @_;

    my @err_img = (); # var for images that can't be found

    # process line by line
    my @lines = split /\n/, $html;
    foreach my $line (@lines) {
        #<img src="THIS TEXT IS WHAT WE ARE LOOKING FOR" >
        if ($line =~ m/.*<img.*\ssrc=["'](\S*)["']\s.*>/g) {
            my $img_path = $1;

            # Is the image existing and readable? If not, push on array
            unless ( -e $img_path and -r $img_path ) {
                push @err_img, $img_path;
            }

            # if we found a path, we add it to a classwide array
            push (@{$self->{picture_paths}}, $img_path);
        }
    }

    # after processing the images... if we found errors we croak!
    if (@err_img >= 1) {
        my $err_list = join ("\n  ", @err_img);
        croak "Could not find this images:\n  $err_list\n"
        . "Aborting! Please make sure that all images are accessible.\n";
    }

}

1;

__END__

=encoding utf8

=head1 NAME

EBook::MOBI::Mhtml2Mobi- Create a Mobi ebook by packing MOBI-ready HTML.

=head1 SYNOPSIS

  use EBook::MOBI::Mhtml2Mobi;
  my $mobi = EBook::MOBI::Mhtml2Mobi->new();
  $mobi->pack($mhtml, $out_filename, $author, $title);

=head1 METHODS

=head2 pack

The input parameters are the following:

  $mhtml     # data to put in the mobi ebook
  $filename  # filename (with path) of the desired ebook
  $author    # author of the ebook
  $title     # title of the ebook
    
Call the method like this:

  $mobi->pack($mhtml, $filename, $author, $title);

After the method call, a Mobi ebook should be found at the path you specified in C<$filename>.

=head3 Handling of Images

If your input data ($mhtml) contains <img> tags which are pointing to images on the filesystem, these images will be stored and linked into the MOBI datafile. The images will be rescaled if necessary, according to L<EBook::MOBI::Image>.

=head1 COPYRIGHT & LICENSE

Copyright 2012, 2013 Boris Däppen, all rights reserved.

Parts of this code are coming from MobiPerl.

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program.  If not, see <http://www.gnu.org/licenses/>.

=head1 AUTHOR

Boris Däppen E<lt>bdaeppen.perl@gmail.comE<gt>

=cut
