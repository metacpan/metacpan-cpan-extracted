package EBook::Tools::PalmDoc;
use warnings; use strict; use utf8;
use version 0.74; our $VERSION = qv("0.5.2");

# Mixed case subs and the variable %record are inherited from Palm::PDB
## no critic (ProhibitAmbiguousNames)
## no critic (ProhibitMixedCaseSubs)
# RequireBriefOpen seems to be way too brief to be useful
## no critic (RequireBriefOpen)

=head1 NAME

EBook::Tools::PalmDoc - Palm::PDB handler for manipulating the PalmDoc/PilotDoc/AportisDoc format

=head1 SYNOPSIS

 use EBook::Tools::PalmDoc qw(uncompress_palmdoc);
 use Palm::PDB;

 my $pdb = Palm::PDB->new();

or

 use EBook::Tools::PalmDoc qw(:all);

 my $pdb = EBook::Tools::PalmDoc->new();
 $pdb->set_text($text);
 $pdb->Write('textfile.pdb');

 my $pdb2 = EBook::Tools::PalmDoc->new();
 $pdb2->{attributes}{resource} = 1;
 $pdb->import_textfile('textfile.txt');
 $pdb->Write('textfile.prc');

=head1 DESCRIPTION

This module contains a L<Palm::PDB> handler (subclassed from
L<Palm::Raw>) and some associated general procedures for dealing with
PalmDoc books.  This handles PalmDoc and only PalmDoc.  For
Mobipocket, eReader, or other .pdb/.prc formats, see the module
specific to the format.

=cut

require Exporter;
use base qw(Exporter Palm::Raw);

our @EXPORT_OK;
@EXPORT_OK = qw (
    &compress_palmdoc
    &parse_palmdoc_header
    &uncompress_palmdoc
    );
our %EXPORT_TAGS = ('all' => [@EXPORT_OK]);

sub import   ## no critic (Always unpack @_ first)
{
    &Palm::PDB::RegisterPDBHandlers( __PACKAGE__, [ "REAd", "TEXt" ], );
    &Palm::PDB::RegisterPRCHandlers( __PACKAGE__, [ "REAd", "TEXt" ], );
    EBook::Tools::PalmDoc->export_to_level(1, @_);
    return;
}

use Carp;
use EBook::Tools qw(debug hexstring);
use File::Basename qw(fileparse);
use Palm::PDB;
use Palm::Raw();

my $htmlsupport = 0;
eval
{
    require HTML::TextToHTML;
    EBook::Tools::DRM->import();
}; # Trailing semicolon is required here
unless($@){ $htmlsupport = 1; }


#################################
########## CONSTRUCTOR ##########
#################################

=head1 CONSTRUCTOR

=head2 C<new()>

Instantiates a new Ebook::Tools::PalmDoc object.  To create a Palm
Resource file instead of a Palm Database file, set
C<< $self->{attributes}{resource} >> to be true immediately after
construction.

Create a new Doc object. By default, it's not a resource database. Setting
C<< $self->{attributes}{resource} >> to C<1> before any manipulations will
cause it to become a resource database.

=cut

sub new   ## no critic (Always unpack @_ first)
{
	my $class = shift;
	my $self = $class->SUPER::new(@_);

	$self->{'creator'} = 'REAd';
	$self->{'type'} = 'TEXt';

	$self->{attributes}{resource} = 0;

	$self->{appinfo} = undef;
	$self->{sort} = undef;
	$self->{records} = [];
        $self->{text} = '';
        $self->{bookmarks} = {};

	return $self;
}


######################################
########## ACCESSOR METHODS ##########
######################################

=head1 ACCESSOR METHODS

=head2 C<bookmarks()>

Returns a hash of bookmarks, where the keys are the bookmark offsets
and the values are the bookmark names.

=cut

sub bookmarks :method
{
    my $self = shift;
    my %bookmarks;

    if($self->{bookmarks} and ref($self->{bookmarks}) eq 'HASH')
    {
        %bookmarks = %{$self->{bookmarks}};
    }
    elsif($self->{bookmarks})
    {
        %bookmarks = $self->{bookmarks}
    }
    else
    {
        %bookmarks = ();
    }
    return %bookmarks;
}


=head2 C<text()>

Returns the text of the file

=cut

sub text :method
{
    my $self = shift;
    my $subname = ( caller(0) )[3];
    debug(2,"DEBUG[",$subname,"]");

    my $length = length($self->{text});

    carp("WARNING: actual text length (",$length,
         ") does not match specified text length (",
         $self->{header}{textlength},")\n")
        unless($length == $self->{header}{textlength});

    return $self->{text};
}


=head2 C<html()>

Returns the text of the file converted to HTML via L<HTML::TextToHTML>.

=cut

sub html :method
{
    my $self = shift;
    my $subname = ( caller(0) )[3];
    debug(2,"DEBUG[",$subname,"]");

    croak("HTML support requires that HTML::TextToHTML be installed!\n")
        unless($htmlsupport);

    my $conv = HTML::TextToHTML->new();
    my $header = "<html>\n<head>\n  <title>" . $self->{name} . "</title>\n";
    $header   .= "</head>\n<body>\n";
    my $footer = "</body>\n</html>\n";

    return $header . $conv->process_chunk($self->{text}) . $footer;
}


######################################
########## MODIFIER METHODS ##########
######################################

=head1 MODIFIER METHODS

These methods have two naming/capitalization schemes -- methods
directly related to the subclassing of Palm::PDB use its
MethodName capitalization style.  Any other methods are
lowercase_with_underscores for consistency with the rest of
EBook::Tools.


=head2 C<ParseRecord(%record)>

Parses PDB records, updating the object attributes.  This method is
called automatically on every database record (in .pdb files) during
C<Load()>.

=cut

sub ParseRecord :method   ## no critic (Always unpack @_ first)
{
    my $self = shift;
    my %record = @_;
    my $subname = ( caller(0) )[3];
    debug(3,"DEBUG[",$subname,"]");

    my $currentrecord = scalar @{$$self{records}};

    if($currentrecord == 0)
    {
        $$self{header} = parse_palmdoc_header($record{data});
        return \%record;
    }

    if($currentrecord <= $$self{header}{textrecords})
    {
        $self->ParseRecordText($record{data});
    }
    else
    {
        # Bookmark records at end of file
        $self->ParseRecordBookmark($record{data},$currentrecord);
    }
    return \%record;
}


=head2 C<ParseResource(%resource)>

Parses PDB resources, updating object attributes.  This is called
automatically on every database resource (in .prc files) during
C<Load()>.

=cut

sub ParseResource :method    ## no critic (Always unpack @_ first)
{
    my $self = shift;
    my %resource = @_;
    my $subname = ( caller(0) )[3];
    debug(3,"DEBUG[",$subname,"]");

    my $currentresource = scalar @{$$self{resources}};

    if($currentresource == 0)
    {
        $self->{header} = parse_palmdoc_header($resource{data});
        return \%resource;
    }

    if($currentresource <= $self->{header}{textrecords})
    {
        $self->ParseRecordText($resource{data});
    }
    else
    {
        # Bookmark records at end of file
        $self->ParseRecordBookmark($resource{data},$currentresource);
    }
    return \%resource;
}


=head2 C<ParseRecordBookmark($data,$currentrecord)>

Parses bookmark records/resources, updating object attributes, most
notably C<< $self->{bookmarks} >>.

The C<$currentrecord> argument is optional, but without it the
debugging information may be less useful.  This is called
automatically by L<ParseRecord()> and L<ParseResource()> as needed.

=cut

sub ParseRecordBookmark :method   ## no critic (Always unpack @_ first)
{
    my $self = shift;
    my ($data,$currentrecord) = @_;
    my $subname = ( caller(0) )[3];
    debug(2,"DEBUG[",$subname,"]");

    $currentrecord = '[unknown]' unless(defined $currentrecord);
    my $bookmark;
    my $offset;

    if(length($data) < 20)
    {
        croak($subname,"(): bookmark record ",$currentrecord,
              " is only ",length($data)," bytes (need 20)\n");
    }
    elsif(length($data) == 20)
    {
        debug(1,"bookmark record ",$currentrecord," is ",
              length($data)," bytes (expected 20)");
    }

    $bookmark = substr($data,0,18);
    $bookmark =~ s/\0+//gx;
    $offset = unpack('n',substr($data,18,2));
    $self->{bookmarks}->{$offset} = $bookmark;
    debug(1,"DEBUG: record ",$currentrecord,
          " is bookmark '",$bookmark,"' [offset ",$offset,"]");
    return 1;
}


=head2 C<ParseRecordText($data)>

Parses text records, updating object attributes, most notably
appending text to C<< $self->{text} >>.

This is called automatically by L</ParseRecord()> and
L</ParseResource()> as needed.

=cut

sub ParseRecordText :method
{
    my $self = shift;
    my $data = shift;
    my $subname = ( caller(0) )[3];
    debug(2,"DEBUG[",$subname,"]");

    my $compression = $self->{header}{compression};

    if($compression == 1)       # No compression
    {
        $self->{text} .= $data;
    }
    elsif($compression == 2)    # PalmDoc compression
    {
        $self->{text} .= uncompress_palmdoc($data);
    }
    else
    {
        croak($subname,"(): unknown compression value (",
              $compression,")\n");
    }
    return 1;
}


=head2 C<set_text(@text)>

Uses the contents of C<@text> (concatenated) as the text of the PDB.

=cut

sub set_text   ## no critic (Always unpack @_ first)
{
    my $self = shift;
    my $text = join('',@_);
    my $subname = ( caller(0) )[3];
    debug(2,"DEBUG[",$subname,"]");

    my $isresource = $self->{attributes}{resource};
    my $record0;
    my $record;
    my $compression = 2;
    my $offset;
    my $textblock;

    $self->{'records'} = [];
    $self->{'resources'} = [];

    $record0 = ($isresource)?
        $self->append_Resource()
        : $self->append_Record();
    $record0->{'compression'} = $compression;
    $record0->{'length'} = 0;
    $record0->{'spare'} = 0;
    $record0->{'textrecords'} = 0;
    $record0->{'recsize'} = 4096;

    for($offset = 0; $offset < length($text); $offset += 4096 )
    {
        $record = ($isresource) ?
            $self->append_Resource
            : $self->append_Record;
        $textblock = substr($text,$offset,4096);
        $record->{'data'} = compress_palmdoc($textblock);

        $record0->{'textrecords'} ++;
        $record0->{'length'} += length($text);
    }
    if($record0->{'length'} < 4096)
    {
        $record0->{'recsize'} = $record0->{'length'};
    }

    $record0->{'data'} =
        pack('nnNnnN',
             $record0->{'compression'}, $record0->{'spare'},
             $record0->{'length'},
             $record0->{'textrecords'}, $record0->{'recsize'}, 0 );

    return 1;
}


=head2 import_textfile($filename)

Set the contents of the Doc to the contents of the file and sets the
name of the PDB to the basename of the file.

=cut

sub import_textfile :method
{
    my $self = shift;
    my $filename = shift;
    my $subname = ( caller(0) )[3];
    debug(2,"DEBUG[",$subname,"]");

    my $fh;
    open($fh,"<:raw",$filename)
        or croak($subname,"(): unable to open '",$filename,"' [",@!,"]");
    $self->set_text('',<$fh>);
    close($fh)
        or croak($subname,"(): unable to close '",$filename,"' [",@!,"]");

    $self->{'name'} = fileparse($filename,'\.\w+$');
    return 1;
}


################################
########## PROCEDURES ##########
################################

=head1 PROCEDURES

All procedures are exportable, but none are exported by default.

=head2 C<compress_palmdoc($text)>

Compresses input text using the simplified Lempel-Ziv 77 encoding used
by PalmDoc and some other formats and returns the compressed string.

See L</uncompress_palmdoc()> for more details on the algorithm.

This procedure was taken from L<Palm::Doc> with some minor changes.

=cut

sub compress_palmdoc
{
    my $text = shift;
    my $subname = ( caller(0) )[3];
    debug(3,"DEBUG[",$subname,"]");

    my $textlength = length($text);
    my $compressed = '';

    debug(1,"WARNING: input text is longer than 4096 bytes (",$textlength,
          " bytes) and may not produce a valid PDB if used.")
        if($textlength > 4096);

    my $offset = 0;
    while($offset < $textlength)
    {
        # See http://web.archive.org/web/20061024025145/http://patb.dyndns.org/Programming/PilotDoc.htm

        # Try type B compression first.
        # If the next 3 to 10 bytes are already in the compressed
        # buffer, we can encode them into a 2 byte sequence. Don't
        # bother too close to the ends, however... Makes the boundary
        # conditions simpler.
        if( $offset > 10 and $textlength - $offset > 10 )
        {
            my $chunk = '';
            my $match = -1;

            # the preamble is what'll be in the decoders output buffer.
            my $preamble = substr( $text, 0, $offset );
            for( my $j = 10; $j >= 3; $j -- )
            {
                $chunk = substr($text,$offset,$j);  # grab next $j characters
                $match = rindex($preamble,$chunk);  # in the output?

                # type B code has a 2047 byte sliding window, so
                # matches have to be within that range to be useful
                last if $match >= 0 and ($offset - $match) <= 2047;
                $match = -1;
            }

            my $n = length $chunk;
            if( $match >= 0 and $n <= 10 and $n >= 3 )
            {
                my $m = $offset - $match;

                # first 2 bits are 10, next 11 are offset, next 3 are length-3
                $compressed .= pack( "n", 0x8000 + (($m<<3)&0x3ff8) + ($n-3) );

                $offset += $n;

                next;
            }
        }

        my $ch = substr( $text, $offset ++, 1 );
        my $och = ord($ch);

        # Try type C compression.
        if( $offset+1 < $textlength and $ch eq ' ' )
        {
            my $nch = substr( $text, $offset, 1 );
            my $onch = ord($nch);

            if( $onch >= 0x40 and $onch < 0x80 )
            {
                # space plus ASCII character compression
                $compressed .= chr($onch ^ 0x80);
                $offset ++;

                next;
            }
        }

        if( $och == 0 or ($och >= 9 and $och < 0x80) )
        {
            # pass through
            $compressed .= $ch;
        }
        else
        {
            # Type A code. This is essentially an 'escape' like '\\'
            # in strings.  For efficiency, it's best to encode as long
            # a sequence as possible with one copy.
            #
            # This might seem like it would cause us to miss out on a
            # type B sequence, but in actuality keeping long binary
            # strings together improves the likelyhood of a later type
            # B sequence than interspersing them with x01's.

            my $next = substr($text,$offset - 1);
            if( $next =~ /([\x01-\x08\x80-\xff]{1,8})/o )
            {
                my $binseq = $1;
                $compressed .= chr(length $binseq);
                $compressed .= $binseq;
                # first char, $ch, is already counted
                $offset += length( $binseq ) - 1;
            }
        }
    }
    return $compressed;
}


=head2 C<parse_palmdoc_header($data)>

Takes as an argument a scalar containing the 16 bytes of the PalmDoc
header (also used by Mobipocket).  Returns a hashref containing those
values keyed to recognizable names.

See:

http://wiki.mobileread.com/wiki/DOC#PalmDOC

and

http://wiki.mobileread.com/wiki/MOBI

=head3 keys

The returned hashref will have the following keys:

=over

=item * C<compression>

Possible values:

=over

=item 1 - no compression

=item 2 - PalmDoc compression

=item 128 - iSilo3?

=item 17480 (the characters 'DH') - Mobipocket 'Dictionary Huffman'
compression (aka HuffDic aka Huff/CDIC)

=back

A warning will be carped if an unknown value is found.

=item * C<textlength>

Uncompressed length of book text in bytes

=item * C<textrecords>

Number of PDB records used for book text

=item * C<recordsize>

Maximum size of each record containing book text. This should always
be 2048 (for some Mobipocket files) or 4096 (for everything else).  A
warning will be carped if it isn't.

=item * C<spare>

Two bytes that should always be zero.  A warning will be carped if
they aren't.

=item * C<unknown12>

32 bits of unknown data, generally zero.  This key may be changed
later if more information is discovered.  Use with caution.

=back

Note that the current position component of the header is discarded.

=cut

sub parse_palmdoc_header
{
    my $data = shift;
    my $subname = ( caller(0) )[3];
    debug(2,"DEBUG[",$subname,"]");

    my %pdbcompression = (
        1 => 'no compression',
        2 => 'PalmDoc compression',
        128 => 'iSilo3 compression',
        17480 => 'Dictionary Huffman compression',
        );

    # We're expecting 16 bytes of data exactly.  We won't croak on
    # more, but it will be reported
    croak($subname,"(): record 0 is too short (only ",
          length($data)," bytes, need at least 16)!\n")
        if(length($data) < 16);
    debug(1,"DEBUG: ",length($data)," bytes of PalmDoc header data",
          " (expected 16)")
        if(length($data) != 16);

    my @list = unpack("nnNnnN",$data);
    my %header;

    $header{compression} = $list[0]; # Bytes 00-01
    $header{spare}       = $list[1]; # Bytes 01-02
    $header{textlength}  = $list[2]; # Bytes 03-07
    $header{textrecords} = $list[3]; # Bytes 08-09
    $header{recordsize}  = $list[4]; # Bytes 10-11
    $header{unknown12}   = $list[5]; # Bytes 12-15

    carp($subname,"(): value ",$header{spare},
         " found in header 'spare' (expected 0)")
        unless($header{spare} == 0);
    carp($subname,"(): found text record size ",$header{recordsize},
         ", expected 2048 or 4096")
        unless($header{recordsize} == 2048
               or $header{recordsize} == 4096);
    carp($subname,"(): found unknown compression value ",$header{compression})
        unless(defined $pdbcompression{$header{compression}});
    debug(1,"DEBUG: PDB compression type is ",
          $pdbcompression{$header{compression}});

    foreach my $key (sort keys %header)
    {
        debug(2,'DEBUG: palmdoc{',$key,'}=0x',sprintf("%04x",$header{$key}));
    }
    return \%header;
}


=head2 C<uncompress_palmdoc($data,%args)>

Uncompresses data compressed using the simplified Lempel-Ziv 77 scheme
used by PalmDoc and some other formats, and returns the uncompressed
string.

If an error is encountered during uncompression outputs a debug
message and returns undef.

=head3 Arguments

C<uncompress_palmdoc> takes one optional named argument:

=over

=item C<trailing>

This specifies the number of trailing bytes to ignore on each record
during decompression.  Extra data such as this is sometimes found on
version 6 Mobipocket records.

=back

=head3 Algorithm

The decoding mechanism is as follows:

Start by reading a byte from the compressed stream.  If the byte is:

=over

=item * 0x00: copy unmodified

=item * 0x01 to 0x08: "Type A" command

This specifies that the next 1-8 bytes are to be copied unmodified.

=item * 0x09 to 0x7f: copy unmodified

=item * 0x80 to 0xbf: "Type B" command

This specifies that the 16 bits (two characters) starting at that
point represent a length-offset pair.  Of the 16 bits that make up
these two bytes, the two leftmost bits (which should be '10') are
simply an identifier and are discarded.  The next 11 bits encode the
offset backwards from the end of uncompressed text, and the last three
encode the length of text to copy from that point (copying n+3 bytes).

=item * 0xc0 to 0xff: "Type C" command

This compresses spaces with the next character, with the value of that
character being XORed with 0x80.

=back

=cut

sub uncompress_palmdoc
{
    my $data = shift;
    my (%args) = @_;
    my $subname = ( caller(0) )[3];
    debug(3,"DEBUG[",$subname,"]");

    my %valid_args = (
        'trailing' => 1,
        );
    foreach my $arg (keys %args)
    {
        croak($subname,"(): invalid argument '",$arg,"'")
            if(!$valid_args{$arg});
    }

    my $trailing = $args{trailing} || 0;
    my $reallength = length($data);
    my $length = $reallength - $trailing;
    my $traildata = substr($data,$length,$trailing);

    my $offset = 0;     # Current offset into data
    my $char;           # Character being examined
    my $ord;            # Ordinal of $char
    my $lz77;           # 16-bit Lempel-Ziv 77 length-offset pair
    my $lz77offset;     # LZ77 offset
    my $lz77length;     # LZ77 length
    my $lz77pos;        # Position inside $lz77length
    my $text = '';      # Output (uncompressed) text
    my $textlength;     # Length of uncompressed text during LZ77 pass
    my $textpos;        # Position inside $text during LZ77 pass

    while($offset < $length)
    {
        $char = substr($data,$offset++,1);
        $ord = ord($char);

        # The long if-elsif chain is the best logic for $ord handling
        ## no critic (Cascading if-elsif chain)
        if($ord == 0)
        {
            # Nulls are literal
            $text .= $char;
        }
        elsif($ord <= 8)
        {
            # Next $ord bytes are literal
            if($offset + $ord > $length)
            {
                debug(1,"WARNING: ",$ord," literal bytes starting at ",$offset,
                      " exceeds data size (",$length,")");
                return $text;
            }
            $text .= substr($data,$offset,$ord);
            $offset += $ord;
        }
        elsif($ord <= 0x7f)
        {
            # Values from 0x09 through 0x7f are literal
            $text .= $char;
        }
        elsif($ord <= 0xbf)
        {
            # Data is LZ77-compressed

            # From Wikipedia:
            # "A length-distance pair is always encoded by a two-byte
            # sequence. Of the 16 bits that make up these two bytes,
            # 11 bits go to encoding the distance, 3 go to encoding
            # the length, and the remaining two are used to make sure
            # the decoder can identify the first byte as the beginning
            # of such a two-byte sequence."

            $offset++;
            if($offset > length($data))
            {
                debug(1,"WARNING: offset to LZ77 bits (",$offset,
                      ") is outside of the data (size ",length($data),")");
                return $text;
            }
            $lz77 = unpack('n',substr($data,$offset-2,2));

            # Leftmost two bits are ID bits and need to be dropped
            $lz77 &= 0x3fff;

            # Length is rightmost 3 bits + 3
            $lz77length = ($lz77 & 0x0007) + 3;

            # Remaining 11 bits are offset
            $lz77offset = $lz77 >> 3;
            if($lz77offset < 1)
            {
                debug(1,"WARNING: LZ77 decompression offset at ",$offset,
                      " is invalid!");
                return;
            }

            # Getting text from the offset is a little tricky, because
            # in theory you can be referring to characters you haven't
            # actually decompressed yet.  You therefore have to check
            # the reference one character at a time.
            $textlength = length($text);
            for($lz77pos = 0; $lz77pos < $lz77length; $lz77pos++)
            {
                $textpos = $textlength - $lz77offset;
                if($textpos < 0)
                {
                    debug(1,"WARNING: LZ77 decompression reference is before",
                          " beginning of text!");
                    debug(2,"  textlength=${textlength}, lz77offset=${lz77offset}");
                    return;
                }
                $text .= substr($text,$textpos,1);
                $textlength++;
            }
        }
        else
        {
            # 0xc0 - 0xff are single characters (XOR 0x80) preceded by
            # a space
            $text .= ' ' . chr($ord ^ 0x80);
        }
    }
    if($reallength > $length)
    {
        debug(3,"DEBUG: skipping ",$trailing," bytes at end of record: 0x",
              hexstring($traildata));
    }
    return $text;
}

1;
__END__


##############################
########## END CODE ##########
##############################

=head1 BUGS

=over

=item * There isn't really any good way to detect the encoding from a
PalmDoc file, and I haven't even tried.  You may have some luck with
L<Encode::Detect>.  On top of this, the encodings aren't entirely
conformant with what you might expect, and vary by version of PalmOS.
See:

L<http://www.df.lth.se/~triad/krad/recode/palm.html>

for details.

=item * PalmDoc files in resource (.prc) form are almost entirely
untested.  Use at your own risk (but feel free to file bug reports).

=item * Although bookmarks can be extracted, they cannot be added to a
new file.

=item * Unit tests are unwritten.

=back

=head1 AUTHOR

Zed Pobre <zed@debian.org>

=head1 COPYRIGHT

Copyright 2008 Zed Pobre

Licensed to the public under the terms of the GNU GPL, version 2

=head1 SEE ALSO

=over

=item * L<EBook::Tools>

=item * L<Palm::PDB>

=item * L<Palm::Doc>

Palm::Doc was the inspiration for this component, but it has been
completely redesigned and the only code remaining from it is in
L</compress_palmdoc()>.

=back

=cut

