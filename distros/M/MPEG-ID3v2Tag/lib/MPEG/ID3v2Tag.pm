use strict;

# This module may be copied under the same terms as perl itself.

# This is a module for reading and writing ID3v2 tags.
#
# see the pod documentation at the bottom for details.

package MPEG::ID3v2Tag;

use vars qw($VERSION);
$VERSION = "0.39";

use Carp;

# Constructor.
sub new {
    my ($package) = @_;

    my $self = {
        FRAMES   => [],
        MAJORVER => 3,
        MINORVER => 0,
    };

    bless $self, $package;
}

####
# Return all the frame objects from the tag.  Either an array or arrayref,
# depending on call context.
#
# If an arrayref is passed in, it will replace the current frame list.
####
sub frames {
    my ( $self, $newframes ) = @_;

    if ($newframes) {
        croak "must pass an arrayref to frames" if ref($newframes) !~ 'ARRAY';
        $self->{FRAMES} = $newframes;
    }

    if (wantarray) {
        return @{ $self->{FRAMES} };
    }
    else {
        return $self->{FRAMES};
    }
}

####
# Delete frame by frame id.
# If n is provided,     deletes frame[n] of that particular frameid
# If n is not provided, deletes all frames with that frame id
####
sub del_frame {
    my ( $self, $frameid, $frameocc ) = @_;

    my $i = 0;
    my @newframes;

    if ( defined $frameocc ) {
        @newframes = grep {
            $_->frameid() ne $frameid
            or (
                $_->frameid() eq $frameid
                and $i++ != $frameocc
            )
        } $self->frames();
    }
    else {
        @newframes = grep { $_->frameid() ne $frameid }
                     $self->frames();
    }

    $self->frames( \@newframes );
}

sub set_frame {
    my $self    = shift;
    my $frameid = shift;

    $self->del_frame($frameid);
    $self->add_frame($frameid, @_);
}

####
# Return the entire tag as a binary string.
####
sub as_string {
    my ($self) = @_;

    my $body = $self->data_as_string();

    if ( $self->flag_unsynchronization && $body =~ /\xff$/ ) {
        $self->set_padding_size(256) if !$self->{PADDING_SIZE};
    }

    if ( $self->flag_extended_header() ) {
        $body = pack(
            "NCCN", 6,    # ext-header-size
            0,            # no flags (I don't support CRC)
            $self->{PADDING_SIZE}
        ) . $body;
    }

    if ( $self->flag_unsynchronization ) {
        $body = unsynchronize($body);
    }

    if (exists($self->{ORIGINAL_SIZE}) && $self->{PADDING_SIZE} && !$self->{MANUAL_PADDING}) {
        # attempt to preserve the original size of the tag by
        # adjusting the padding size.
        my $padlen = $self->{ORIGINAL_SIZE} - length($body);

        if ( $padlen >= 0 ) {
            $self->set_padding_size($padlen);
        }
    }

    if ( $self->{PADDING_SIZE} ) {
        $body .= "\0" x $self->{PADDING_SIZE};
    }

    my $size = length($body);

    my $flags = ( ( !!$self->flag_unsynchronization() ) << 7 )
              | ( ( !!$self->flag_extended_header()   ) << 6 )
              | ( ( !!$self->flag_experimental()      ) << 5 );

    return "ID3" . pack( "CCCN", 3, 0, $flags, MungeSize($size) ) . $body;
}

####
# Set the amount of nul-padding to add at the end of the tag, in bytes.
####
sub set_padding_size {
    my ( $self, $size ) = @_;

    $self->{PADDING_SIZE} = $size;
    $self->flag_extended_header(1) if ($size);

    # remember that the user set the padding, so we don't try to maintain
    # the same tag size in as_string()
    $self->{MANUAL_PADDING} = 1;
}

####
# Perform "unsynchronization" on the data.  This takes things that
# look like mpeg syncs, 11111111 111xxxxx, and stuffs a zero
# in between the bytes.  In addition, it stuffs a zero after every
# ff 00 combination.
#
# Note that this is A.F.U., because the standard doesn't say to stuff
# an extra zero in 11111111 00000000 111xxxxx.  It says to stuff it
# after 11111111 00000000.  That's broken.  Seems to be what id3lib
# does also, though.
#
####
sub unsynchronize {
    my ($data) = @_;

    # zero stuff after ff 00
    $data =~ s/\xff\0/\xff\0\0/g;

    # zero stuff between 11111111 111xxxxx
    $data =~ s/\xff(?=[\xe0-\xff])/\xff\x00/g;

    return $data;
}

####
# Reverse the unsyncrhonization process.
####
sub un_unsynchronize {
    my ($data) = @_;

    $data =~ s/\xff\x00([\xe0-\xff])/\xff$1/g;
    $data =~ s/\xff\x00\x00/\xff\x00/g;

    return $data;
}

####
# Return all the formatted frames as a big binary string.
####
sub data_as_string {
    my $self = shift;

    my $data = "";

    for my $frame (@{ $self->frames() }) {
        $data .= $frame->as_string();
    }

    return $data;
}

####
# Add a new frame's data to the id3 tag.
#  You can either call this with an MPEG::ID3Frame object, or you can
# call it with a four-letter frame ID code plus arguments.
# If you send the frame code, add_frame will go looking for
# a new() method in the package MPEG::ID3Frame::<frame_code> and call
# it with the specified arguments.
#
# Returns the frame that was added.
####
sub add_frame {
    my ( $self, $frame, @args ) = @_;

    if ( length($frame) == 4 && @args ) {
        # they passed us a frame id and constructor arguments.
        # Construct an object of the appropriate type and make it format
        # its data.

        my $frameid = $frame;
        my $package = "MPEG::ID3Frame::$frameid";

        if ( !$package->can("new") ) {
            croak "Frame type $frameid is not implemented";
        }

        eval { $frame = $package->new(@args) };
        if ($@) {
            chomp $@;    # trailing newline.
            $@ =~ s/ at.*$//;    # at file line#
            croak $@ ;
        }
    }

    if ( !$frame->isa("MPEG::ID3Frame") ) {
        croak "strange arguments to append_frame()";
    }

    push @{ $self->{FRAMES} }, $frame;

    return $frame;
}

####
# Find a frame by frame id.
# In list context, returns all the matching frames.
# In scalar context, returns just the first match.
####
sub get_frame {
    my ( $self, $frameid ) = @_;

    my @frames = grep { $_->frameid() eq $frameid } $self->frames();

    if (wantarray) {
        return @frames;
    }
    else {
        return $frames[0];
    }
}

# create a bunch of flag routines
for my $flag (qw(unsynchronization extended_header experimental)) {
    eval <<EOT ;
  sub flag_$flag
  {
    my \$self = shift ;
    if (\@_) {
      # there was a parameter
      \$self->{FLAGS}{"$flag"} = \$_[0] ;
    }

    return \$self->{FLAGS}{"$flag"} ;
  }
EOT
    die $@ if $@;
}

####
# Given an open filehandle, parse out the ID3 tag, if any.
# Constructs a new tag object (it's a static method).
####
sub parse {
    my ( $package, $fh ) = @_;

    my $tag = {};
    my $str;

    my ( $header, $data, $place );

    if ( ( ref $fh ) eq 'GLOB' ) {
        my $readlen = read( $fh, $header, 10 );
        croak "$!"   if !defined $readlen;
        if ($readlen < 10) {
            carp "Read less than 10 bytes";
            return undef;
        }
    }
    else {    ##not a filehandle. asume its a scalar
        $place = index( $fh, "ID3" );    ##the real start of the ID3 Tag!!
        if ($place < 0) {
            carp "'ID3' not found in header";
            return undef;
        }
        $header = substr( $fh, $place, 10 );
    }

    my ( $id3, $flags, $totalsize );

    ( $id3, $tag->{MAJORVER}, $tag->{MINORVER}, $flags, $totalsize )
        = unpack( "a3CCCN", $header );

    $totalsize = UnMungeSize($totalsize);
    $tag->{ORIGINAL_SIZE} = $totalsize;

    if ($id3 ne 'ID3') {
        carp "Header does not begin with 'ID3'";
        return undef;
    }
    if ($tag->{MAJORVER} < 3) {
        carp "ID3 tag version is 2.$tag->{MAJORVER}.$tag->{MINORVER}, less than 2.3.0";
        return undef;
    }

    bless $tag, $package;

    $tag->flag_unsynchronization( ( $flags >> 7 ) & 1 );
    $tag->flag_extended_header(   ( $flags >> 6 ) & 1 );
    $tag->flag_experimental(      ( $flags >> 5 ) & 1 );

    if ( ( ref $fh ) eq 'GLOB' ) {
        my $len = 0;

        while ( $len < $totalsize ) {
            my $readlen = read( $fh, $data, $totalsize - $len, $len );
            croak "$!" if !defined $readlen;
            last       if $readlen == 0;
            $len += $readlen;
        }
    }
    else {
        # easier if not a filehandle
        $data = substr( $fh, $place + 10, $totalsize );
    }

    # now we have all the tag data, minus the main header, in $data.
    $data = un_unsynchronize($data) if $tag->flag_unsynchronization();

    # if there's an extended header, peel it off the front of the data
    # and parse it.
    if ( $tag->flag_extended_header() ) {
        # peel off the header size
        $str = substr( $data, 0, 4, "" );
        my $extheader_size = unpack( "N", $str );

        # peel the header
        my $extheader = substr( $data, 0, $extheader_size, "" );
        $str = substr( $extheader, 0, 6, "" );

        # two bytes of flags, then four byte padding size.
        ( $flags, undef, $tag->{PADDING_SIZE} ) = unpack( "CCN", $str );

        # at this point, anything left in the extended header is stuff
        # I don't know what to do with, including maybe a CRC value that I'm
        # ignoring.

        # If there is any padding, strip it off the end of the data
        # and throw it away (it's supposed to be all nuls).

        if ( $tag->{PADDING_SIZE} ) {
            substr( $data, -$tag->{PADDING_SIZE}, $tag->{PADDING_SIZE}, "" );
        }
    }

    # Now data contains just the frames.  If it's id3v2.3 it won't have
    # padding, but if it's id3v2.4, it might.  Parse until the data is 
    # empty or all padding.

    while ( $data ne '' and $data !~ /^\0+$/ ) {
        my $frame = MPEG::ID3Frame->parse( \$data, $tag );
        $tag->add_frame($frame);
    }

    # done!

    return $tag;
}

sub UnMungeSize {
    my ($size) = @_;
    my $newsize = 0;

    my $pos;

    for ( $pos = 0; $pos < 4; $pos++ ) {
        my $mask = 0xff << ( $pos * 8 );

        my $val = ( $size & $mask ) >> ( $pos * 8 );

        $newsize |= $val << ( $pos * 7 );
    }

    return $newsize;
}

# Takes an integer and returns an ID3 size field
sub MungeSize {
    my ($size) = @_;

    my $newsize = 0;
    my $pos;

    for ( $pos = 0; $pos < 4; $pos++ ) {
        my $val = ( $size >> ( $pos * 7 ) ) & 0x7f;
        $newsize |= $val << ( $pos * 8 );
    }

    return $newsize;
}

sub dump {
    my $self = shift;

    print "----Frames:\n";

    for my $frame ( $self->frames() ) {
        $frame->dump();
    }
}

###############################################################################
#  MPEG::ID3Frame
#
#  This is a base class from which other classes need to be derived.
# To implement a particular frame type, such as UFID, create a new
# class MPEG::ID3Frame::UFID (or whatever), and follow the directions
# in the pod.
#
# See the pod for what this class can do.
#
##############################################################################
package MPEG::ID3Frame;
use Carp;

# DO NOT WRITE A new() METHOD FOR THIS CLASS!

####
# This is just a placeholder.  In derived classes this would return
# the four-letter id code for the frame type.
####
sub frameid {
    my $self = shift;
    return $self->{FRAMEID} if ( $self->{FROM_PARSER} );
    confess "Must get frameid() from a derived class";
}

####
# Format the entire frame as a string ready for output to the file.
####
sub as_string {
    my $self = shift;
    my $data = $self->data_as_string();

    if ( $self->flag_encryption || $self->flag_grouping_identity ) {
        # these extend the headers.
        carp "unsupported flag used, header will be wrong.";
    }

    # The musicmatch id3lib doesn't munge frame header sizes.
    # That seems to be correct.
    # Only the ID3 header itself needs to take care to avoid false
    # syncs, because the body is handled by the unsync. scheme.

    if ( $self->flag_compression && !exists $self->{UNSUPPORTED_BODY} ) {
        # require Compress::Zlib here so the module stays functional
        # without it.

        require Compress::Zlib;
        Compress::Zlib->import( "compress", "uncompress" );

        my $compressed_data = compress($data);

        croak "Error in Compress::Zlib::compress"
            if !defined $compressed_data;

        return $self->frameid()
            . pack( "N", 4 + length($compressed_data) ) # 4 is for "N" length $data
            . $self->flags_as_string()
            . pack( "N", length($data) )
            . $compressed_data;
    }
    else {
        return $self->frameid()
            . pack( "N", length($data) )
            . $self->flags_as_string
            . $data;
    }
}

####
# Return the data as a binary string.
# This private method must be overridden in a derived class.
####
sub data_as_string {
    my $self = shift;

    if ( $self->{FROM_PARSER} && exists $self->{UNSUPPORTED_BODY} ) {
        return $self->{UNSUPPORTED_BODY};
    }

    confess "Must get data_as_string from a derived class";
}

####
#  Return true iff the parsing module was able to fully parse this
# object so the data is useful.
#
# It could return false for any number of reasons, generally either
# an unsupported frame or an unsupported feature like compression
# or encryption.
####
sub fully_parsed {
    my $self = shift;
    return !exists( $self->{UNSUPPORTED_BODY} );
}

# create flag get/set subroutines for supported frame flags.
my @flags = qw(
    tag_alter file_alter read_only compression encryption 
    grouping_identity
);

for my $flag (@flags) {
    eval <<"EOT" ;
    sub flag_$flag {
      my (\$self, \$value) = \@_ ;
      if (defined \$value) {
	\$self->{FLAGS}{"$flag"} = \$value ;
      } else {
	return \$self->{FLAGS}{"$flag"} ;
      }
    }
EOT
    die $@ if $@;
}

####
# Some tags require a default of 1 for the file_alter flag.
# This function gets exported as flag_file_alter to those packages in
# the for loop below this.
####
sub flag_file_alter_default_1 {
    my ( $self, $value ) = @_;

    if ( defined $value ) {
        $self->{FLAGS}{"flag_file_alter"} = $value;
    }
    else {
        if ( exists $self->{FLAGS}{"flag_file_alter"} ) {
            return $self->{FLAGS}{"flag_file_alter"};
        }
        else {
            return 1;
        }
    }
}

# According to section 3.3.2 of the informal v2.3.0 spec, these frames
# need to default to discarded-if-file-altered = 1, so override the
# flag_file_alter method for those frames to the right default.
my @frameids = qw(
    AENC ETCO EQUA MLLT POSS SYLT SYTC RVAD TENC TLEN TSIZ
);

for my $frameid (@frameids) {
    # perl magic to stick a reference to a subroutine into a package's
    # symbol table as a different subroutine name.  Scary stuff, but
    # better than evaling in 11 new copies of the same function,
    # and safer than another layer of inheritance.
    no strict 'refs';

    *{"MPEG::ID3Frame::${frameid}::flag_file_alter"}
        = \&flag_file_alter_default_1;
}

####
# Return the header flags as a binary string.
# Private method.
####
sub flags_as_string {
    my $self = shift;

    my ( $byte0, $byte1 );

    $byte0 = ( $self->flag_tag_alter()  << 7 )
           | ( $self->flag_file_alter() << 6 )
           | ( $self->flag_read_only()  << 5 );
    $byte1 = ( $self->flag_compression()       << 7 )
           | ( $self->flag_encryption()        << 6 )
           | ( $self->flag_grouping_identity() << 5 );
    return pack( "CC", $byte0, $byte1 );
}

####
# Static method/ctor to parse the frame from the front of a string
# and return an appropriate MPEG::ID3Frame::* object.
# A reference to the binary string is passed in, and the data
# is peeled from the front of that string.
#
# Actually calls MPEG::ID3Frame::<tagname>::parse_data to do the
# frame data parsing.  Headers here, data there.
####
sub parse {
    my ( $package, $dataref, $tag ) = @_;
    my $self = { FROM_PARSER => 1 };
    my ( $body, $original_body );
    my $tmp;
    bless $self, $package;

    my $header = substr( $$dataref, 0, 10, "" );
    my ( $frameid, $size, $flags0, $flags1 ) = unpack( "a4NCC", $header );
    $self->{FRAMEID} = $frameid;

    if ( defined $tag and $tag->{MAJORVER} == 4 ) {
        $size = MPEG::ID3v2Tag::UnMungeSize($size);
    }

    $self->flag_tag_alter(  ( $flags0 >> 7 ) & 1 );
    $self->flag_file_alter( ( $flags0 >> 6 ) & 1 );
    $self->flag_read_only(  ( $flags0 >> 5 ) & 1 );

    $self->flag_compression(       ( $flags1 >> 7 ) & 1 );
    $self->flag_encryption(        ( $flags1 >> 6 ) & 1 );
    $self->flag_grouping_identity( ( $flags1 >> 5 ) & 1 );

    $original_body = $body = substr( $$dataref, 0, $size, "" );

    if ( $self->flag_encryption() || $self->flag_grouping_identity() ) {
        # we don't know how to parse this field because we don't support
        # encryption.  We will still return the frame, and
        # it will still be output ok.  We just can't do anything with the
        # data contained.

        $self->{UNSUPPORTED_BODY}   = $original_body;
        $self->{UNSUPPORTED_REASON} = "Unsupported flag";
        return $self;
    }

    if ( $self->flag_compression() ) {
        eval {
            require Compress::Zlib;
            Compress::Zlib->import( "compress", "uncompress" );
        };
        if ($@) {
            $self->{UNSUPPORTED_BODY}   = $original_body;
            $self->{UNSUPPORTED_REASON} = $@;
            return $self;
        }

        # four bytes after header are actually uncompressed data size.
        $tmp = substr( $body, 0, 4, "" );
        my $uc_size = unpack( "N", $tmp );

        $body = uncompress($body);
        if ( !defined $body || length($body) != $uc_size ) {
            $self->{UNSUPPORTED_BODY} = $original_body;
            if ( defined $body ) {
                $self->{UNSUPPORTED_REASON} = "compress size mismatch";
            }
            else {
                $self->{UNSUPPORTED_REASON} = "zlib compress error";
            }
            return $self;
        }
    }

    # now we've stripped away all the headers and we can attempt to
    # parse the body.

    # Look in MPEG::ID3Frame::<frameid> for a parse_data method.
    # if there is one, rebless this frame object into that package
    # and call the method.

    my $frame_package = "MPEG::ID3Frame::$frameid";
    if ( $frame_package->can("parse_data") ) {
        bless $self, $frame_package;
        $self->parse_data($body);

        if ( $self->{UNSUPPORTED_BODY} ) {
            # the frame's parse_data set up an UNSUPPORTED_BODY,
            # which means they got some kind of error and they couldn't
            # complete the parse.

            # That means they really aren't a MPEG::ID3Frame::$frameid,
            # they're a generic frame, so re-rebless them back to
            # the generic frame package.
            bless $self, $package;

            # and they wouldn't know if we had passed them something
            # that was originally compressed, so we'll use the body
            # we started with rather than the one they gave us back.
            # so it'll still be compressed on output.
            $self->{UNSUPPORTED_BODY} = $original_body;

            # but we'll keep their reason, whatever that was.
        }

    }
    else {
        $self->{UNSUPPORTED_BODY} = $original_body;
        $self->{UNSUPPORTED_REASON} = "No MPEG::ID3Frame::$frameid parse_data method";
    }

    return $self;
}

sub dump {
    my $self = shift;

    if ( $self->{UNSUPPORTED_BODY} ) {
        my $reason = $self->{UNSUPPORTED_REASON};
        print $self->frameid(), " (unparsed: $reason)\n";
    }
    else {
        print $self->frameid(), " (no dump method)\n";
    }
}

###############################################################################
# MPEG::ID3Frame::Text
#    MPEG::ID3Frame::TALB
#    MPEG::ID3Frame::TBPM
#    MPEG::ID3Frame::TCOM
#                ... and so on for all T??? frame types.
#
#  This class is derived from MPEG::ID3Frame, and from this is derived all the
# MPEG::ID3Frame::T??? fields.   It is not useful on its own.
#
# This section of the file will also create derived classes for all the
# Text types (TALB, TBPM, etc).  Note that TEXT is not the same as Text.
###############################################################################
package MPEG::ID3Frame::Text;
use Carp;

use vars '@ISA';

@ISA = qw(MPEG::ID3Frame);

sub new {
    my $package = shift;
    my $self;
    if ( @_ == 1 ) {
        $self = {
            ENCODING => 0,
            DATA     => $_[0]
        };
    }
    elsif ( @_ == 2 ) {
        $self = {
            ENCODING => $_[0],
            DATA     => $_[1]
        };
    }
    else {
        croak "Wrong # arguments to MPEG::ID3Frame::Text::new\n";
    }
    bless $self, $package;
}

####
# Given the body portion of a text-type tag, parse out the encoding and data
# portions.
####
sub parse_data {
    my ( $self, $data ) = @_;

    #  ($self->{ENCODING}, $self->{DATA}) = unpack("CZ*", $data) ;
    $self->{ENCODING} = unpack( "C", substr( $data, 0, 1 ) );

    if ( $self->{ENCODING} == 0 ) {
        $self->{DATA} = unpack( "Z*", substr( $data, 1 ) );
    }
    elsif ( $self->{ENCODING} == 1 ) {    ##with BOM
        ######## a really dirty hack to change the UNICODE to normal ISO-8859-1  this will of course
        ######## destroy the real unicode. so no need to write a UNICODE back to file
        my @text_as_list;
        $self->{BOM} = unpack( "n", substr( $data, 1, 2 ) );
        if ( $self->{BOM} == 0xfeff ) {
            @text_as_list = unpack( "n*", substr( $data, 3 ) );
        }
        else {
            @text_as_list = unpack( "v*", substr( $data, 3 ) );
        }
        $self->{DATA} = pack( "C*", @text_as_list );
        $self->{ENCODING} = 0;    ## now
    }
    elsif ( $self->{ENCODING} == 2 ) {    #no BOM here   ##never tested
        ######## a really dirty hack to change the UNICODE to normal ISO-8859-1  this will of course
        ######## destroy the real unicode. so no need to write a UNICODE back to file

        ## I hope this n is working for ENCODING type 2. else change to back to v like type 1
        my @text_as_list;
        @text_as_list = unpack( "v*", substr( $data, 1 ) );
        $self->{DATA} = pack( "C*", @text_as_list );
        $self->{ENCODING} = 0;    ## now
    }
    elsif ( $self->{ENCODING} == 3 ) {    ##never tested
        my @text_as_list;
        @text_as_list = unpack( "U*", substr( $data, 1 ) );
        $self->{DATA} = pack( "C*", @text_as_list );
        $self->{ENCODING} = 0;    ## now
    }
}

sub encoding { return $_[0]->{ENCODING} }
sub text     { return $_[0]->{DATA} }

####
# Override for MPEG::ID3Frame::frameid().  returns the frame id, the
# four-letter word identifying the frame type.
####
sub frameid {
    my ($self) = @_;
    my $frameid = ref $self;
    $frameid =~ s/^.*:://;
    if ( $frameid eq 'Text' || $frameid eq 'Url' ) {
        confess "Must get frameid() from a derived class";
    }
    return $frameid;
}

####
# Return the data portion of this frame, formatted as a binary string.
####
sub data_as_string {
    my ($self) = @_;

    # zero for encoding=latin-1, and the rest is just the text, nul-terminated.
    return pack( "CZ*", $self->{ENCODING}, $self->{DATA} );
}

sub dump {
    my $self = shift;
    print $self->frameid(), " (enc=", $self->encoding, ") ", $self->text, "\n";
}

# automatically derive a ton of classes from this one.
my @derived_frameids = qw(
    TALB TBPM TCOM TCON TCOP TDAT TDLY TENC TEXT TFLT TIME TIT1 TIT2 
    TIT3 TKEY TLAN TLEN TMED TOAL TOFN TOLY TOPE TORY TOWN TPE1 TPE2 
    TPE3 TPE4 TPOS TPUB TRCK TRDA TRSN TRSO TSIZ TSRC TSSE TYER
);

my $evalstr;
for my $frameid (@derived_frameids) {
    $evalstr .= <<EOT
    \@MPEG::ID3Frame\::$frameid\::ISA = qw(MPEG::ID3Frame::Text) ;
EOT
}

eval $evalstr;
die $@ if $@;
undef $evalstr;

###############################################################################
# MPEG::ID3Frame::Url
#    MPEG::ID3Frame::WCOM
#    MPEG::ID3Frame::WCOP
#    MPEG::ID3Frame::WOAF
#                ... and so on for all W??? frame types.
#
#  This class is derived from MPEG::ID3Frame, and from this is derived all the
# MPEG::ID3Frame::W??? fields.   It is not useful on its own.
#
# It steals its new and frameid() methods from ::Text.  That's kinda
# sloppy; they should both derive from some class.
#
# This section of the file will also create derived classes for all the
# URL types (WCOM, WCOP, etc).
###############################################################################
package MPEG::ID3Frame::Url;
use Carp;

use vars '@ISA';

@ISA = qw(MPEG::ID3Frame::Text);

####
# Return the data portion of this frame, formatted as a binary string.
####
sub data_as_string {
    my ($self) = @_;

    return $self->{DATA} . "\0";
}

####
# Given the body portion of a text-type tag, parse out the encoding and data
# portions.
####
sub parse_data {
    my ( $self, $data ) = @_;

    ( $self->{DATA} ) = unpack( "Z*", $data );
}

sub url { return $_[0]->{DATA} }

sub dump {
    my $self = shift;
    print $self->frameid(), " ", $self->url(), "\n";
}

# automatically derive a bunch of classes from this one.
for my $frameid (qw(WCOM WCOP WOAF WOAR WOAS WORS WPAY WPUB)) {
    $evalstr .= <<EOT
    \@MPEG::ID3Frame\::$frameid\::ISA = qw(MPEG::ID3Frame::Url) ;
EOT
}

#print $evalstr ;
eval $evalstr;
die $@ if $@;
undef $evalstr;

##############################################################################
# MPEG::ID3Frame::UFID
#  Unique file Identifier frame type.
##############################################################################
package MPEG::ID3Frame::UFID;
use vars '@ISA';
@ISA = qw(MPEG::ID3Frame);
use Carp;

sub frameid () { return "UFID" }

sub new {
    my ( $package, $owner_id, $id ) = @_;
    my $self = {
        OWNER_ID => $owner_id,
        ID       => $id
    };
    bless $self, $package;
}

sub data_as_string {
    my $self = shift;

    return $self->{OWNER_ID} . "\0" . $self->{ID};
}

##############################################################################
# MPEG::ID3Frame::USLT
#  Unsynchronized lyrics/text transcription frame.
##############################################################################
package MPEG::ID3Frame::USLT;
use Carp;
use vars '@ISA';
@ISA = qw(MPEG::ID3Frame);
use Carp;

sub frameid () { return "USLT" }

sub new {
    my ( $package, $encoding, $language, $content_descriptor, $lyrics ) = @_;
    croak "language must be a three letter code" if length($language) != 3;
    my $self = {
        ENCODING     => $encoding,
        LANGUAGE     => $language,
        CONTENT_DESC => $content_descriptor,
        LYRICS       => $lyrics
    };
    bless $self, $package;
}

sub encoding           { return $_[0]->{ENCODING} }
sub language           { return $_[0]->{LANGUAGE} }
sub content_descriptor { return $_[0]->{CONTENT_DESC} }
sub lyrics             { return $_[0]->{LYRICS} }

sub data_as_string {
    my $self = shift;

    return pack( "Ca3Z*", $self->{ENCODING}, $self->{LANGUAGE}, $self->{CONTENT_DESC} . "\0" )
        . $self->{LYRICS} . "\0";
}

sub parse_data {
    my ( $self, $data ) = @_;

    my $tmp = substr( $data, 0, 4, "" );
    ( $self->{ENCODING}, $self->{LANGUAGE} ) = unpack( "Ca3", $tmp );
    ( $self->{CONTENT_DESC}, $self->{LYRICS} ) = ( $data =~ /^(.*?)\x00(.*)\x00/s );
}

sub dump {
    my $self = shift;
    printf "%s (enc=%d lang=%s desc=%s)\n", $self->frameid(),
        $self->encoding(), $self->language(), $self->content_descriptor();
    my $lyrics = $self->lyrics;
    $lyrics =~ s/^/  | /mg;
    print $lyrics ;
}

##############################################################################
# MPEG::ID3Frame::APIC
#  attached picture.
##############################################################################
package MPEG::ID3Frame::APIC;
use Carp;
use IO::File;
use vars '@ISA';
@ISA = qw(MPEG::ID3Frame);
use Carp;

sub frameid () { return "APIC" }

sub new {
    my $package = shift;
    my $self    = {
        PICTURETYPE => 0,
        ENCODING    => 0,
        DESCRIPTION => " "
    };
    my $fh;
    my $fname;

    while ( @_ && $_[0] =~ /^-/ ) {
        my $arg = shift;
        if ( $arg =~ /^-encoding/ ) {
            $self->{ENCODING} = shift(@_);
        }
        elsif ( $arg =~ /^-mime/ ) {
            $self->{MIMETYPE} = shift(@_)
                || croak "bad argument to -mimetype";
        }
        elsif ( $arg =~ /^-picture_type/ || $arg =~ /-type/ ) {
            $self->{PICTURETYPE} = shift(@_);
        }
        elsif ( $arg =~ /^-desc/ ) {
            $self->{DESCRIPTION} = shift(@_);
        }
        elsif ( $arg =~ /^-fh/ ) {
            $fh = shift(@_) || croak "bad argument to -fh";
        }
        elsif ( $arg =~ /^-fn/ || $arg =~ /^-file/ ) {
            $fname = shift(@_) || croak "bad argument to $arg";
        }
        elsif ( $arg =~ /^-data/ || $arg =~ /^-data/ ) {
            $self->{DATA} = shift(@_) || croak "bad argument to $arg";
        }
        else {
            croak "unknown switch $arg";
        }
    }
    croak "bad arguments to APIC" if @_;

    if ( !exists $self->{MIMETYPE} ) {
        if ($fname) {
            if ( $fname =~ /\.gif$/i ) {
                $self->{MIMETYPE} = "image/gif";
            }
            elsif ( $fname =~ /\.jpg/ ) {
                $self->{MIMETYPE} = "image/jpeg";
            }
        }
    }
    if ( !exists $self->{MIMETYPE} ) {
        croak "must specify a -mimetype";
    }

    if ( !exists $self->{DATA} ) {
        if ( !defined $fh ) {
            croak "must specify -data, -file, or -fh" if ( !defined $fname );
            $fh = IO::File->new("<$fname") || croak "$fname: $!\n";
        }
        local $/ = undef;    # file slurp mode
        $self->{DATA} = <$fh>;
    }

    bless $self, $package;
}

sub data_as_string {
    my $self = shift;

    my $data = pack( "CZ*", $self->{ENCODING}, $self->{MIMETYPE} )
        . pack( "CZ*", $self->{PICTURETYPE}, $self->{DESCRIPTION} )
        . $self->{DATA};

    return $data;
}

##############################################################################
# MPEG::ID3Frame::USER
#  terms of use frame.
##############################################################################
package MPEG::ID3Frame::USER;
use Carp;
use vars '@ISA';
@ISA = qw(MPEG::ID3Frame);
use Carp;

sub frameid () { return "USER" }

sub new {
    my ( $package, $encoding, $language, $text ) = @_;
    croak "language must be a three letter code" if length($language) != 3;
    my $self = {
        ENCODING => $encoding,
        LANGUAGE => $language,
        TEXT     => $text
    };
    bless $self, $package;
}

sub data_as_string {
    my $self = shift;

    return pack( "Ca3a*", $self->{ENCODING}, $self->{LANGUAGE}, $self->{TEXT} );
}

##############################################################################
# MPEG::ID3Frame::COMM
#  comment frame.
##############################################################################
package MPEG::ID3Frame::COMM;
use Carp;
use vars '@ISA';
@ISA = qw(MPEG::ID3Frame);
use Carp;

sub frameid () { return "COMM" }

sub new {
    my ( $package, $encoding, $language, $description, $text ) = @_;
    croak "language must be a three letter code" if length($language) != 3;
    my $self = {
        ENCODING    => $encoding,
        LANGUAGE    => $language,
        DESCRIPTION => $description,
        TEXT        => $text
    };
    bless $self, $package;
}

sub parse_data {
    my ( $self, $data ) = @_;

    ( $self->{ENCODING}, $self->{LANGUAGE} ) = unpack( "Ca3", substr( $data, 0, 4 ) );

    my $textpos = index( $data, "\0", 4 ) + 1;
    my $desc = substr( $data, 4, $textpos - 5 );
    my $text = substr( $data, $textpos );

    if ( $self->{ENCODING} == 0 ) {
        $self->{DESCRIPTION} = $desc;
        $self->{TEXT}        = $text;
    }
    elsif ( $self->{ENCODING} == 1 ) {    ##with BOM
        ######## a really dirty hack to change the UNICODE to normal ISO-8859-1  this will of course
        ######## destroy the real unicode. so no need to write a UNICODE back to file
        my @text_as_list_t;
        my @text_as_list_d;

        $self->{BOM} = unpack( "n", substr( $data, 1, 2 ) );
        if ( $self->{BOM} == 0xfeff ) {
            @text_as_list_t = unpack( "n*", substr( $text, 2 ) );
            @text_as_list_d = unpack( "n*", substr( $desc, 2 ) );
        }
        else {
            @text_as_list_t = unpack( "v*", $text );
            @text_as_list_d = unpack( "v*", $desc );
        }
        $self->{DESCRIPTION} = pack( "C*", @text_as_list_d );
        $self->{TEXT}        = pack( "C*", @text_as_list_t );
        $self->{ENCODING} = 0;    ## now
    }

}

sub data_as_string {
    my $self = shift;

    return pack( "Ca3a*", $self->{ENCODING}, $self->{LANGUAGE}, $self->{DESCRIPTION} . "\0" . $self->{TEXT} );
}

##############################################################################
# MPEG::ID3Frame::WXXX
#  User defined URL link frame
##############################################################################
package MPEG::ID3Frame::WXXX;
use Carp;
use vars '@ISA';
@ISA = qw(MPEG::ID3Frame);
use Carp;

sub frameid () { return "WXXX" }

sub new {
    my ( $package, $encoding, $description, $url ) = @_;
    my $self = {
        ENCODING    => $encoding,
        DESCRIPTION => $description,
        URL         => $url
    };
    bless $self, $package;
}

sub parse_data {
    my ( $self, $data ) = @_;
    my $desc_url;

    ( $self->{ENCODING}, $desc_url ) = unpack( "Ca*", $data );
    ( $self->{DESCRIPTION}, $self->{URL} ) = split( "\0", $desc_url );
}

sub encoding    { return $_[0]->{ENCODING} }
sub description { return $_[0]->{DESCRIPTION} }
sub url         { return $_[0]->{URL} }

sub data_as_string {
    my $self = shift;

    return pack( "Ca*", $self->{ENCODING}, $self->{DESCRIPTION} . "\0" . $self->{URL} );
}

##############################################################################
# MPEG::ID3Frame::TXXX
#  User defined text frame
##############################################################################
package MPEG::ID3Frame::TXXX;
use Carp;
use vars '@ISA';
@ISA = qw(MPEG::ID3Frame);
use Carp;

sub frameid () { return "TXXX" }

sub new {
    my ( $package, $encoding, $description, $data ) = @_;
    my $self = {
        ENCODING    => $encoding,
        DESCRIPTION => $description,
        DATA        => $data
    };
    bless $self, $package;
}

sub parse_data {
    my ( $self, $data ) = @_;
    my $desc_data;

    ( $self->{ENCODING}, $desc_data ) = unpack( "Ca*", $data );
    ( $self->{DESCRIPTION}, $self->{DATA} ) = split( "\0", $desc_data );
}

sub encoding    { return $_[0]->{ENCODING} }
sub description { return $_[0]->{DESCRIPTION} }
sub text        { return $_[0]->{DATA} }

sub data_as_string {
    my $self = shift;

    return pack( "Ca*", $self->{ENCODING}, $self->{DESCRIPTION} . "\0" . $self->{DATA} );
}

1;

__END__

=pod

=head1 NAME

B<MPEG::ID3v2Tag> - Parses and creates ID3v2 Tags for MPEG audio files.

=head1 SYNOPSIS

  use MPEG::ID3v2Tag;
  use IO::File;
  
  # create a tag
  $tag = MPEG::ID3v2Tag->new();
  $tag->add_frame( "TIT2", "Happy Little Song" );    # one step
  $frame = MPEG::ID3Frame::TALB->new("Happy little album");
  $tag->add_frame($frame);                           # two steps
  $tag->add_frame( "WCOM", "http://www.mp3.com" );
  $tag->add_frame(
      "APIC",
      -picture_type => 0,
      -file         => "happy_little_song.gif"
  );
  .....
  $tag->set_padding_size(256);
  print OUTFILE $tag->as_string();
  
  # read a tag from a file and dump out some data.
  $fh = IO::File->new("<happysong.mp3");
  binmode $fh;
  $tag = MPEG::ID3v2Tag->parse($fh);
  for $frame ( $tag->frames() ) {
      print $frame->frameid(), "\n";    # prints TALB, TIT2, WCOM, etc.
      if ( $frame->flag_read_only() ) {
          print "  read only\n";
      }
      if ( $frame->fully_parsed() && $frame->frameid =~ /^T.../ ) {
          print "  frame text is ", $frame->text(), "\n";
      }
      if ( $frame->fully_parsed() && $frame->frameid =~ /^W.../ ) {
          print "  url is ", $frame->url(), "\n";
      }
  }

=head1 DESCRIPTION

MPEG::ID3v2Tag is a class capable of parsing and creating ID3v2 revision
3 tags.  While not all frames are fully supported, it's easy to add
support for more.

The object doesn't (currently) support modification of .mp3 files;
the caller has to handle the mechanics of prepending the tag to the file.

=head1 METHODS

=over 4

=item $tag = MPEG::ID3v2Tag->new()

Creates a C<MPEG::ID3v2Tag>.  Takes no parameters.

=item $arrayref = $tag->frames()

=item @array    = $tag->frames()

Returns an array or arrayref containing all the MPEG::ID3Frame-derived
objects from the tag.  See FRAME SUPPORT for details on what frames
can do.

=item $tagdata = $tag->as_string

Returns the complete tag, formatted as a binary string, ready to be
slapped on the front of an .mp3 file.

=item $tag->set_padding_size($bytes)

Sets the number of bytes of padding to add at the end of the tag.
This will be added as zero bytes.  Also sets the extended_header flag
if $bytes > 0.

=item $tag->add_frame($frame)

=item $tag->add_frame($frameid, [arguments])

Adds a new frame to the end of the tag.  The first form takes an object
derived from the class MPEG::ID3Frame and simply appends it to the
list of frames.  The second will take a four-letter frame id code
(TALB, RBUF, SYLT, etc.) and attempt to call the new() method of
the class MPEG::ID3Frame::<frameid> to create the frame to be added.
The arguments to the constructor will be those passed to ->add_frame(),
minus the frame id.  If there is no new method, it will die.

For details on the arguments for supported frames, see the
FRAME SUPPORT section.

=item @frames = $tag->get_frame(frameid)

Given a four-letter frame id, this method will search the tag's frames
for all that match and return them.  If called in scalar context,
it will return just the first one found, if any.

=item $tag->flag_unsynchronization([1|0])

=item $tag->flag_extended_header([1|0])

=item $tag->flag_experimental([1|0])

These get and set the flags for the ID3v2 header.  If an argument is
passed, the flag will be set to that value.  The current flag value
is returned.

If flag_unsynchronization is set when as_string() is called, the
unsynchronization scheme will be applied to the data portion of the
tag.

If flag_extended_header is set when as_string() is called, an
ID3v2 Extended Header will be added.  This flag is set automatically
when set_padding_size() is set to a non-zero value.

=item MPEG::ID3v2Tag->parse($filehandle)

This method will construct a new tag by reading from a file containing
an ID3v2 tag.  If there is no revision 3 tag in the file, undef is
returned.

The filehandle should be in binary mode.  This is not necesary on some 
platforms, but it is on others, so it's a good habit to get into.

Frame types for which a parse_data method has been written will
be parsed individually, and (should) provide appropriate access methods
to retrieve the data contained in the frame.

All frame types, whether supported by a MPEG::ID3Frame subclass or not,
will be read in and will be formatted appropriately when output with
$tag->as_string().  You just won't be able to do anything with the data
inside the tag unless a parser has been written.

This method will read the tag and leave the filehandle's file pointer 
at the byte immediately following the tag.

See FRAME SUPPORT for details about frames and their parsers.

=item $tag->dump()

Dumps out the tag to the currently selected filehandle, for debugging
purposes.

=head1 FRAME SUPPORT

Each ID3v2 frame type is implemented by its own class.  TALB is
implemented by MPEG::ID3Frame::TALB, OWNE is implemented by
MPEG::ID3Frame::OWNE, etc.

Not all frames are currently implemented for writing, and not all
frames that are implemented for writing have parsers for reading.

All frames support the following public methods, which they get from a
base class called MPEG::ID3Frame.

=item $id = $frame->frameid()

Returns the four-letter frame id code for the frame.

=item $frame->fully_parsed()

When a frame is read from an ID3v2 tag which has been parsed by
MPEG::ID3v2Tag->parse(), actually parsing the data into a useful
form may turn out to be impossible.  For example, the appropriate
parser routine may not be implemented, or the tag may contain a
flag demanding unimplemented functionality like encryption.

This method can be used to determine whether the tag was parsed
into its component bits.

If this routine returns a false value, the reason the tag could
not be parsed may be found in the $frame->{UNSUPPORTED_REASON}
private variable.

Note that even if a frame can't be parsed, it can still be 
retained in the tag when it is output with the $tag->as_string()
method.  It will be output exactly as it appeared in the data
stream when it was read in.

=item $frame->flag_tag_alter([1|0])

=item $frame->flag_file_alter([1|0])

=item $frame->flag_read_only([1|0])

=item $frame->flag_compression([1|0])

=item $frame->flag_encryption([1|0])

=item $frame->flag_grouping_identity([1|0])

These functions get and/or set the flag bits from the frame header.
See the ID3v2.3.0 informal standard for semantics.

Note that encryption is not currently supported,
and that attempting to create frames with these bits turned on may
create bad headers.

If you set the compression flag on a frame, this module will attempt
to load the Compress::Zlib module to compress the frame, dying if
the module can't be found.  When parsing a compressed frame,
Compress::Zlib will be used if available.  If not, the frame will
not be parsed (the fully_parsed method will tell you if a frame
was successfully parsed, and $frame->{UNSUPPORTED_REASON} will give
you a string telling you why), but no fatal errors will be generated.

=item $frame->dump()

Dumps out some data from this frame.  This is generally overridden
in subclasses to dump frame-specific data.

=head2 Support for specific frame types

In addition to the above methods, each individual supported frame will
have a new() constructor (which can be called directly, or implicitly by
$tag->add_frame()) and possibly access methods for the data contained
in the frame.  In the list below, the constructor is shown as a call
to $tag->add_frame(<tagname>, <arguments>), but remember you can 
call MPEG::ID3Frame::TALB->new(<arguments>) and pass the return
value to add_frame.

=item TALB

=item TBPM

=item TCOM

=item .... and so on T???

All these text information frames are supported:

TALB TBPM TCOM TCON TCOP TDAT TDLY TENC 
TEXT TFLT TIME TIT1 TIT2 TIT3 TKEY TLAN 
TLEN TMED TOAL TOFN TOLY TOPE TORY TOWN 
TPE1 TPE2 TPE3 TPE4 TPOS TPUB TRCK TRDA 
TRSN TRSO TSIZ TSRC TSSE TYER

The constructor is generally called like this:

[$frame = ]$tag->add_frame(TALB, "text string", [optional_encoding]) ;

You can get the encoding value with $frame->encoding() and the
text string value with $frame->text().

Parsing is implemented for these frames.

=item WCOM

=item WCOP

=item .... and so on  (W???)

All url link frames are supported:
WCOM WCOP WOAF WOAR WOAS WORS WPAY WPUB

The constructor is generally called like this:

[$frame = ]$tag->add_frame(WCOM, "text string", [optional_encoding]) ;

You can read back the url with $frame->url().

=item UFID

Call the constructor like this:

[$frame = ]$tag->add_frame(UFID, $owner_idstring, $id) ;

There is currently no parsing support.

=item USLT

Call the constructor like this:

$tag->add_frame(USLT, $encoding, $language, $content_descriptor, $lyrics) ;

also supports parsing, and these access methods: encoding(), language(), content_descriptor(), and lyrics() ;

=item APIC

This is one of the more complicated frames.

The constructor is called as

$tag->add_frame(APIC, [switches])

where switches can be:

-encoding => $encoding

-mime[type] => $mime_type

-picture_type => $picture_type

-desc[ription] => $description

-fh => $filehandle

-fn[ame] => $filename

-data => $data

At least one of -fh, -fn, or -data must be provided.  -data takes the
images as a binary string.  -fh provides an open filehandle on the image
file, and -fn provides a file for reading.

-mimetype must be provided also.  However, if -fname is used, and the
filename ends in '.gif' or '.jpg', the mime type will be assumed 
'image/gif' or 'image/jpg'.

There is currently no parsing support.

=item USER

The constructor for the Terms of Use frame is called as

$tag->add_frame("USER", $encoding, $language, $text) ;

There is no parsing support.

=item COMM

The constructor for the Comments frame is called as

$tag->add_frame("COMM", $encoding, $language, $description, $text) ;

There is no parsing support.

=item WXXX

This is for user-defined url link frames.

$tag->add_frame("WXXX", $encoding, $description, $url) ;

Parsing support exists.  As well as the following accessor methods:
encoding, description, url

=item TXXX

This is for user-defined text fields

$tag->add_frame("TXXX", $encoding, $description, $text) ;

Parsing support exists.  As well as the following accessor methods:
encoding, description, text

=head1 SUPPORTING NEW FRAMES

Adding support for more frames is very simple.  In general,
all you need to do is copy and tweak one of the supported frames (USER
is a nice simple one to start from).

Suppose we're adding support for frame XXXX.  Read the section about
XXXX in the ID3v2.3.0 spec, then...

Create a new package MPEG::ID3Frame::XXXX.

Derive it from MPEG::ID3Frame (put "MPEG::ID3Frame" in its @ISA
array).

create a subroutine/method called frameid() that just returns "XXXX".

create a constructor called new(), which takes whatever arguments
you will need.

create a data_as_string method to construct the frame based on
the ID3v2.3.0 spec.  pack() is helpful, here.

Optionally, create access methods for the data you passed in in your
constructor.

Optionally, create a parse_data method which takes the data portion
of the frame and parses out the data so your access methods can 
access them.  If your parser finds it can't parse the body data,
it should set $self->{UNSUPPORTED_BODY} to the string passed in,
and $self->{UNSUPPORTED_REASON} to a short string giving the reason
it failed.

Optionally, create a dump() method.

Make sure that you get the same answer if you write out the frame,
read it in, and write it out again.

=head1 BUGS

Creating tags with encryption will probably explode.

Encrypted tags can't be parsed.  They can be read in
and written back out, however.

UNICODE character encodings will currently fail on input or output.

No support for modifying .mp3 files.

Many frame types unimplemented.

Most frame types don't have parsers.
