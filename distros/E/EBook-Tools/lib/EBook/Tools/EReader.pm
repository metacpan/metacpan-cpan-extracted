package EBook::Tools::EReader;
use warnings; use strict; use utf8;
use version 0.74; our $VERSION = qv("0.5.2");

# Double-sigils are needed for lexical variables in clear print statements
## no critic (Double-sigil dereference)
# Mixed case subs and the variable %record are inherited from Palm::PDB
## no critic (ProhibitAmbiguousNames)
## no critic (ProhibitMixedCaseSubs)

=head1 NAME

EBook::Tools::EReader - Palm::PDB handler for manipulating the Fictionwise/PeanutPress eReader format.

=head1 SYNOPSIS

 use EBook::Tools::EReader;
 my $pdb = EBook::Tools::EReader->new();
 $pdb->Load('myfile-er.pdb');
 print "Loaded '",$pdb->{title},"' by ",$pdb->{author},"\n";
 my $html = $pdb->html;
 my $pml = $pdb->pml
 $pdb->write_unknown_records

=head1 DEPENDENCIES

=over

=item * C<Compress::Zlib>

=item * C<Image::Size>

=item * C<P5-Palm>

=back

=cut


require Exporter;
use base qw(Exporter Palm::Raw);

our @EXPORT_OK;
@EXPORT_OK = qw (
    &cp1252_to_pml
    &pml_to_html
    );
our %EXPORT_TAGS = ('all' => [@EXPORT_OK]);

sub import   ## no critic (Always unpack @_ first)
{
    &Palm::PDB::RegisterPDBHandlers( __PACKAGE__, [ "PPrs", "PNRd" ], );
    &Palm::PDB::RegisterPRCHandlers( __PACKAGE__, [ "PPrs", "PNRd" ], );
    EBook::Tools::EReader->export_to_level(1, @_);
    return;
}

use Carp;
use Compress::Zlib;
use EBook::Tools qw(debug split_metadata system_tidy_xhtml);
use EBook::Tools::PalmDoc qw(uncompress_palmdoc);
use Encode;
use Fcntl qw(SEEK_CUR SEEK_SET);
use File::Basename qw(dirname fileparse);
use File::Path;     # Exports 'mkpath' and 'rmtree'
use HTML::TreeBuilder;
use Image::Size;
use List::Util qw(min);
use List::MoreUtils qw(uniq);
use Palm::PDB;
use Palm::Raw();


#################################
########## CONSTRUCTOR ##########
#################################

=head1 CONSTRUCTOR

=head2 C<new()>

Instantiates a new Ebook::Tools::EReader object.

=cut

sub new   ## no critic (Always unpack @_ first)
{
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    $self->{'creator'} = 'PNRd';
    $self->{'type'} = 'PPrs';

    $self->{attributes}{resource} = 0;

    $self->{appinfo} = undef;
    $self->{sort} = undef;
    $self->{records} = [];

    $self->{header} = {};
    $self->{text} = '';

    $self->{title}     = '';
    $self->{author}    = '';
    $self->{rights}    = '';
    $self->{publisher} = '';
    $self->{isbn}      = '';

    return $self;
}


######################################
########## ACCESSOR METHODS ##########
######################################

=head1 ACCESSOR METHODS

=head2 C<filebase>

In scalar context, this is the basename of the object attribute
C<filename>.  In list context, it actually returns the basename,
directory, and extension as per C<fileparse> from L<File::Basename>.

=cut

sub filebase
{
    my $self = shift;
    return fileparse($$self{filename},'\.\w+$');
}


=head2 C<footnotes()>

Returns a hash containing all of the footnotes found in the file,
where the keys are the footnote ids and the values contain the
footnote text.

=cut

sub footnotes
{
    my $self = shift;
    my $subname = ( caller(0) )[3];
    debug(2,"DEBUG[",$subname,"]");

    my %footnotehash;
    my @footnoteids = ();
    my @footnotes = ();
    my $lastindex;

    if(ref $self->{footnoteids} eq 'ARRAY' and @{$self->{footnoteids}})
    {
        @footnoteids = @{$self->{footnoteids}};
    }

    if(ref $self->{footnotes} eq 'ARRAY' and @{$self->{footnotes}})
    {
        @footnotes = @{$self->{footnotes}};
    }

    if($#footnotes != $#footnoteids)
    {
        carp($subname,"(): found ",scalar(@footnotes)," footnotes but ",
             scalar(@footnoteids)," footnote ids\n");
    }
    $lastindex = min($#footnotes, $#footnoteids);

    foreach my $idx (0 .. $lastindex)
    {
        $footnotehash{$footnoteids[$idx]} = $footnotes[$idx];
    }

    return %footnotehash;
}


=head2 C<footnotes_pml()>

Returns a string containing all of the footnotes in a form suitable to
append to the end of PML text output.  This is called as part of
L</pml()>.

=cut

sub footnotes_pml
{
    my $self = shift;
    my $subname = ( caller(0) )[3];
    debug(2,"DEBUG[",$subname,"]");

    my %footnotehash = $self->footnotes;
    my $text = '';

    foreach my $footnoteid (sort keys %footnotehash)
    {
        $text .= '<footnote id="' . $footnoteid . '">';
        $text .= $footnotehash{$footnoteid};
        $text .= "</footnote>\n\n";
    }
    return $text;
}


=head2 C<footnotes_html()>

Returns a string containing all of the footnotes in a form suitable to
append to the end of HTML text output.  This is called as part of
L</html()>.

=cut

sub footnotes_html
{
    my $self = shift;
    my $subname = ( caller(0) )[3];
    debug(2,"DEBUG[",$subname,"]");

    my %footnotehash = $self->footnotes;
    my $text = '<h2 id="footnotes">Footnotes</h2>';
    $text .= "\n<dl>\n";

    foreach my $footnoteid (sort keys %footnotehash)
    {
        $text .= '<dt>[<a id="' . $footnoteid . '" href="#';
        $text .= $footnoteid . '-ref">' . $footnoteid;
        $text .= "</a>]</dt>\n";

        $text .= '<dd>' . $footnotehash{$footnoteid} . "</dd>\n";
    }
    $text .= "</dl>\n";
    $text = pml_to_html($text,$self->filebase);
    return $text;
}


=head2 C<pml()>

Returns a string containing the entire original document text in its
original encoding, including all sidebars and footnotes.

=cut

sub pml
{
    my $self = shift;
    my $subname = ( caller(0) )[3];
    debug(2,"DEBUG[",$subname,"]");
    debug(2,"DEBUG: returning ",length($self->{text})," bytes of PML text");
    return $self->{text} . "\n" . $self->sidebars_pml . $self->footnotes_pml;
}


=head2 C<html()>

Returns a string containing the entire document text (including all
sidebars and footnotes) converted to HTML.

Note that the PML text is stored in the object (and thus retrieving it
is very fast), but generating the HTML output requires that the text
be converted every time this method is used, consuming extra
processing time.

=cut

sub html
{
    my $self = shift;
    my $subname = ( caller(0) )[3];
    debug(2,"DEBUG[",$subname,"]");

    my $header = <<"END";
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
 "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<head>
  <title>$self->{title}</title>
</head>
<body>
END
    my $footer = "</body>\n</html>\n";

    return
      $EBook::Tools::utf8xmldec . $header
        . pml_to_html($self->{text},$self->filebase)
        . $self->sidebars_html . $self->footnotes_html . $footer;
}


=head2 C<sidebars()>

Returns a hash containing all of the sidebars found in the file, where
the keys are the sidebar ids and the values contain the sidebar text.

=cut

sub sidebars
{
    my $self = shift;
    my $subname = ( caller(0) )[3];
    debug(2,"DEBUG[",$subname,"]");

    my %sidebarhash;
    my @sidebarids = ();
    my @sidebars = ();
    my $lastindex;

    if(ref $self->{sidebarids} eq 'ARRAY' and @{$self->{sidebarids}})
    {
        @sidebarids = @{$self->{sidebarids}};
    }

    if(ref $self->{sidebars} eq 'ARRAY' and @{$self->{sidebars}})
    {
        @sidebars = @{$self->{sidebars}};
    }

    if($#sidebars != $#sidebarids)
    {
        carp($subname,"(): found ",scalar(@sidebars)," sidebars but ",
             scalar(@sidebarids)," sidebar ids\n");
    }
    $lastindex = min($#sidebars, $#sidebarids);

    foreach my $idx (0 .. $lastindex)
    {
        $sidebarhash{$sidebarids[$idx]} = $sidebars[$idx];
    }

    return %sidebarhash;
}


=head2 C<sidebars_pml()>

Returns a string containing all of the sidebars in a form suitable to
append to the end of PML text output.  This is called as part of
L</pml()>.

=cut

sub sidebars_pml
{
    my $self = shift;
    my $subname = ( caller(0) )[3];
    debug(2,"DEBUG[",$subname,"]");

    my %sidebarhash = $self->sidebars;
    my $text = '';

    foreach my $sidebarid (sort keys %sidebarhash)
    {
        $text .= '<sidebar id="' . $sidebarid . '">';
        $text .= $sidebarhash{$sidebarid};
        $text .= "</sidebar>\n\n";
    }
    return $text;
}


=head2 C<sidebars_html()>

Returns a string containing all of the sidebars in a form suitable to
append to the end of HTML text output.  This is called as part of
L</html()>.

=cut

sub sidebars_html
{
    my $self = shift;
    my $subname = ( caller(0) )[3];
    debug(2,"DEBUG[",$subname,"]");

    my %sidebarhash = $self->sidebars;
    my $text = '<h2 id="sidebars">Sidebars</h2>';
    $text .= "\n<dl>\n";

    foreach my $sidebarid (sort keys %sidebarhash)
    {
        $text .= '<dt>[<a id="' . $sidebarid . '" href="#';
        $text .= $sidebarid . '-ref">' . $sidebarid;
        $text .= "</a>]</dt>\n";

        $text .= '<dd>' . $sidebarhash{$sidebarid} . "</dd>\n";
    }
    $text .= "</dl>\n";
    $text = pml_to_html($text,$self->filebase);
    return $text;
}


=head2 C<write_html($filename)>

Writes the raw book text to disk in PML form (including all sidebars
and footnotes) with the given filename.

If C<$filename> is not specified, writes to C<< $self->filebase >> with
a ".html" extension.

Returns the filename used on success, or undef if there was no text to
write.

=cut

sub write_html :method
{
    my $self = shift;
    my $filename = shift;
    my $subname = ( caller(0) )[3];
    debug(3,"DEBUG[",$subname,"]");

    $filename = $self->filebase . ".html" unless($filename);
    return unless($$self{text});

    debug(1,"DEBUG: writing HTML text to '",$filename,"'");

    open(my $fh,'>:encoding(UTF-8)',$filename)
        or croak($subname,"(): unable to open '",$filename,"' for writing!\n");
    print {*$fh} $self->html;
    close($fh)
        or croak($subname,"(): unable to close '",$filename,"'!\n");

    croak($subname,"(): failed to generate any text")
        if(-z $filename);

    return $filename;
}


=head2 C<write_images()>

Writes each image record to the disk.

Returns a list containing the filenames of all images written, or
undef if none were found.

=cut

sub write_images :method
{
    my $self = shift;
    my $subname = ( caller(0) )[3];
    debug(3,"DEBUG[",$subname,"]");

    return unless($self->{imagedata});
    my %imagedata = %{$self->{imagedata}};
    my $imagedir = $self->filebase . "_img";

    mkpath($imagedir);

    foreach my $image (sort keys %imagedata)
    {
        debug(1,"Writing image '",$imagedir,"/",$image,"' [",
              length(${$imagedata{$image}})," bytes]");
        open(my $fh,">:raw","$imagedir/$image")
            or croak("Unable to open '$imagedir/$image' to write image\n");
        print {*$fh} ${$imagedata{$image}};
        close($fh)
            or croak("Unable to close image file '$imagedir/$image'\n");
    }
    return keys %imagedata;
}


=head2 C<write_pml($filename)>

Writes the raw book text to disk in PML form (including all sidebars
and footnotes) with the given filename.

If C<$filename> is not specified, writes to C<< $self->filebase >> with
a ".pml" extension.

Returns the filename used on success, or undef if there was no text to
write.

=cut

sub write_pml :method
{
    my $self = shift;
    my $filename = shift;
    my $subname = ( caller(0) )[3];
    debug(3,"DEBUG[",$subname,"]");

    $filename = $self->filebase . ".pml" unless($filename);
    return unless($$self{text});

    debug(1,"DEBUG: writing PML text to '",$filename,"'");

    open(my $fh,">:raw",$filename)
        or croak($subname,"(): unable to open '",$filename,"' for writing!\n");
    print {*$fh} $self->pml;
    close($fh)
        or croak($subname,"(): unable to close '",$filename,"'!\n");

    croak($subname,"(): failed to generate any text")
        if(-z $filename);

    return $filename;
}


=head2 C<write_unknown_records()>

Writes each unidentified record to disk with a filename in the format of
'raw-record-####', where #### is the record number (not the record ID).

Returns the number of records written.

=cut

sub write_unknown_records :method
{
    my $self = shift;
    my $subname = ( caller(0) )[3];
    debug(3,"DEBUG[",$subname,"]");

    my %unknowndata = %{$self->{unknowndata}};

    foreach my $rec (sort keys %unknowndata)
    {
        my $recstring = sprintf("%04d",$rec);
        debug(1,"Dumping raw record ",$recstring);
        my $rawname = "raw-record-" . $recstring;
        open(my $fh,">:raw",$rawname)
            or croak("Unable to open '",$rawname,"' to write raw record\n");
        print {*$fh} $$self{unknowndata}{$rec};
        close($fh)
            or croak("Unable to close raw record file '",$rawname,"'\n");
    }
    return scalar(keys %unknowndata);
}


######################################
########## MODIFIER METHODS ##########
######################################

=head1 MODIFIER METHODS

=head2 C<Load($filename)>

Sets C<< $self->{filename} >> and then loads and parses the file specified
by C<$filename>, calling L</ParseRecord(%record)> on every record
found.

=cut

sub Load :method
{
    my $self = shift;
    my $filename = shift;

    $self->{filename} = $filename;
    return $self->SUPER::Load($filename);
}


=head2 C<ParseRecord(%record)>

Parses PDB records, updating the object attributes.  This method is
called automatically on every database record during C<Load()>.

=cut

sub ParseRecord :method   ## no critic (Always unpack @_ first)
{
    ## The long if-elsif chain is the best logic for record number handling
    ## no critic (Cascading if-elsif chain)
    my $self = shift;
    my %record = @_;
    my $subname = ( caller(0) )[3];
    debug(3,"DEBUG[",$subname,"]");

    my $currentrecord = scalar @{$$self{records}};
    my $version = $self->{header}->{version};
    my $recordtext;

    my $uncompress;  # Coderef to decompression sub

    if($currentrecord == 0)
    {
        $self->ParseRecord0($record{data});
        return \%record;
    }

    # Determine how to handle the remaining records
    if($version == 2)
    {
        $uncompress = \&uncompress_palmdoc;
    }
    elsif($version == 10)
    {
        $uncompress = \&uncompress;
    }
    elsif($version > 255)
    {
        croak($subname,"(): eReader DRM not supported [version ",
              $version,"]\n");
    }
    else
    {
        croak($subname,"(): unknown eReader version: ",$version,"\n");
    }


    # Start handling non-header records
    if($currentrecord < $self->{header}->{nontextoffset})
    {
        $recordtext = $uncompress->($record{data});
        $recordtext =~ s/\0//x;
        if($recordtext)
        {
            $self->{text} .= $recordtext;
            debug(3,"DEBUG: record ",$currentrecord," is text");
        }
        else
        {
            debug(1,"DEBUG: record ",$currentrecord,
                  " could not be decompressed (",
                  length($record{data})," bytes)");
            $$self{unknowndata}{$currentrecord} = $record{data};
        }
    }
    elsif($currentrecord >= $self->{header}->{nontextoffset}
          && $currentrecord < $self->{header}->{bookmarkoffset})
    {
        $recordtext = uncompress($record{data});
        $recordtext = uncompress_palmdoc($record{data}) unless($recordtext);
        if($recordtext)
        {
            $$self{unknowndata}{$currentrecord} = $recordtext;
            debug(1,"DEBUG: record ",$currentrecord," contains ",
                  length($record{data})," bytes of unknown text");
        }
        else
        {
            $$self{unknowndata}{$currentrecord} = $record{data};
            debug(1,"DEBUG: record ",$currentrecord," contains ",
                  length($record{data})," bytes of unknown data");
        }
    }
    elsif($currentrecord >= $self->{header}->{bookmarkoffset}
          && $currentrecord < $self->{header}->{imagedataoffset})
    {
        my @list = unpack('nn',$record{data});
        $recordtext = substr($record{data},4);
        $recordtext =~ s/\0//gx;

        debug(3,"DEBUG: record ",$currentrecord," is bookmark '",
              $recordtext,
              "' [",sprintf("unk=0x%04x offset=0x%04x",@list),"]");
    }
    elsif($currentrecord >= $self->{header}->{imagedataoffset}
          && $currentrecord < $self->{header}->{metadataoffset})
    {
        my $pngoffset = index($record{data},"\x{89}PNG",5);
        my $imagedata = substr($record{data},$pngoffset);
        my ($imagetype,$imagename) = $record{data} =~ m/^ (\w+) \s (.*?)\0/x;
        debug(1,"DEBUG: record ",$currentrecord," is ",$imagetype,
              " image at offset ",$pngoffset,": '",$imagename,"'");
        $$self{imagedata}{$imagename} = \$imagedata;
    }
    elsif($currentrecord == $self->{header}->{metadataoffset})
    {
        debug(1,"DEBUG: record ",$currentrecord," contains ",
              length($record{data})," bytes of metadata");
        # The metadata record consists of five null-terminated
        # strings
        my @list = $record{data} =~ m/(.*?)\0/gx;
        $self->{title}     = $list[0];
        $self->{author}    = $list[1];
        $self->{rights}    = $list[2];
        $self->{publisher} = $list[3];
        $self->{isbn}      = $list[4];
    }
    elsif($self->{header}->{sidebarrecs}
          && $currentrecord == $self->{header}->{sidebaroffset})
    {
        my @sidebarids = $record{data} =~ m/(\w+)\0/gx;
        $self->{sidebarids} = \@sidebarids;
        debug(2,"DEBUG: record ",$currentrecord," has sidebar ids: '",
              join("' '",@sidebarids),"'");
    }
    elsif($self->{header}->{sidebarrecs}
          && $currentrecord > $self->{header}->{sidebaroffset}
          && $currentrecord < $self->{header}->{footnoteoffset})
    {
        my @sidebars;
        my @sidebarids;

        if(ref $self->{sidebarids} eq 'ARRAY' and @{$self->{sidebarids}})
        {
            @sidebarids = @{$self->{sidebarids}};
        }
        else
        {
            carp($subname,
                 "(): adding a footnote, but no footnote IDs found\n");
            @sidebarids = [];
        }

        if(ref $self->{sidebars} eq 'ARRAY' and @{$self->{sidebars}})
        {
            @sidebars = @{$self->{sidebars}};
        }

        $recordtext = $uncompress->($record{data});
        if($recordtext)
        {
            $recordtext =~ s/\0//x;
            chomp($recordtext);
            push(@sidebars,$recordtext);
        }

        if( scalar(@sidebars) > scalar(@sidebarids) )
        {
            carp($subname,
                 "(): sidebar ",scalar(@sidebars),
                 " has no associated ID\n");
        }
        else
        {
            debug(2,"DEBUG: record ",$currentrecord," is sidebar '",
                  $sidebarids[$#sidebars],"'");
        }

        $self->{sidebars} = \@sidebars;
    }
    elsif($self->{header}->{footnoterecs}
          && $currentrecord == $self->{header}->{footnoteoffset})
    {
        my @footnoteids = $record{data} =~ m/(\w+)\0/gx;
        $self->{footnoteids} = \@footnoteids;
        debug(2,"DEBUG: record ",$currentrecord," has footnote ids: '",
              join("' '",@footnoteids),"'");
    }
    elsif($self->{header}->{footnoterecs}
          && $currentrecord > $self->{header}->{footnoteoffset}
          && $currentrecord < $self->{header}->{lastdataoffset})
    {
        my @footnotes;
        my @footnoteids;

        if(ref $self->{footnoteids} eq 'ARRAY' and @{$self->{footnoteids}})
        {
            @footnoteids = @{$self->{footnoteids}};
        }
        else
        {
            carp($subname,
                 "(): adding a footnote, but no footnote IDs found\n");
            @footnoteids = [];
        }

        if(ref $self->{footnotes} eq 'ARRAY' and @{$self->{footnotes}})
        {
            @footnotes = @{$self->{footnotes}};
        }

        $recordtext = $uncompress->($record{data});
        if($recordtext)
        {
            $recordtext =~ s/\0//x;
            chomp($recordtext);
            push(@footnotes,$recordtext);
        }

        if( scalar(@footnotes) > scalar(@footnoteids) )
        {
            carp($subname,
                 "(): footnote ",scalar(@footnotes),
                 " has no associated ID\n");
        }
        else
        {
            debug(2,"DEBUG: record ",$currentrecord," is footnote '",
                  $footnoteids[$#footnotes],"'");
        }

        $self->{footnotes} = \@footnotes;
    }
    else
    {
        my ($imagex,$imagey,$imagetype) = imgsize(\$record{data});
        $recordtext = uncompress($record{data});
        $recordtext = uncompress_palmdoc($record{data}) unless($recordtext);
        if(defined($imagex) && $imagetype)
        {
            debug(1,"DEBUG: record ",$currentrecord," is image");
            $$self{unknowndata}{$currentrecord} = $record{data};
        }
        elsif($recordtext)
        {
            debug(1,"DEBUG: record ",$currentrecord," has extra text:");
            debug(1,"       '",$recordtext,"'");
            $$self{unknowndata}{$currentrecord} = $recordtext;
        }
        else
        {
            debug(1,"DEBUG: record ",$currentrecord," is unknown (",
                  length($record{data})," bytes)");
            $$self{unknowndata}{$currentrecord} = $record{data};
        }
    }
    return \%record;
}


=head2 C<ParseRecord0($data)>

Parses the header record and places the parsed values into the hashref
C<< $self->{header} >>.

Returns the hash (not the hashref).

=cut

sub ParseRecord0 :method
{
    my $self = shift;
    my $data = shift;
    my $subname = ( caller(0) )[3];
    debug(2,"DEBUG[",$subname,"]");

    my $version;     # EReader version
                     # Expected values are:
                     # 02 - PalmDoc Compression
                     # 10 - Inflate Compression
                     # >255 - data is in Record 1
    my $headerdata;  # used for holding temporary data segments
    my $offset;
    my %header;
    my @list;

    debug(1,"DEBUG: EReader Record 0 is ",length($data)," bytes");
    $headerdata = substr($data,0,16);
    @list = unpack('nnNnnnn',$headerdata);
    $header{version}        = $list[0]; # Bytes 0-1
    $header{unknown2}       = $list[1]; # Bytes 2-3
    $header{unknown4}       = $list[2]; # Bytes 4-7
    $header{unknown8}       = $list[3]; # Bytes 8-9
    $header{unknown10}      = $list[4]; # Bytes 10-11
    $header{nontextoffset}  = $list[5]; # Bytes 12-13
    $header{nontextoffset2} = $list[5]; # Bytes 14-15

    $headerdata = substr($data,16,16);
    @list = unpack('nnNnnnn',$headerdata);
    $header{unknown16}    = $list[0];
    $header{unknown18}    = $list[1];
    $header{unknown20}    = $list[2];
    $header{unknown22}    = $list[3];
    $header{unknown24}    = $list[4];
    $header{footnoterecs} = $list[5];
    $header{sidebarrecs}  = $list[6];

    $headerdata = substr($data,32,24);
    @list = unpack('nnnnnnnnnnnn',$headerdata);
    $header{bookmarkoffset}   = $list[0];
    $header{unknown34}        = $list[1];
    $header{nontextoffset3}   = $list[2];
    $header{unknown38}        = $list[3];
    $header{imagedataoffset}  = $list[4];
    $header{imagedataoffset2} = $list[5];
    $header{metadataoffset}   = $list[6];
    $header{metadataoffset2}  = $list[7];
    $header{footnoteoffset}   = $list[8];
    $header{sidebaroffset}    = $list[9];
    $header{lastdataoffset}   = $list[10];
    $header{unknown54}        = $list[11];

    # If the footnoteoffset and sidebarrec are the same, only one or the
    # other exists, and there's no way to tell which.

    $offset = 60;
    while($headerdata = substr($data,$offset,4))
    {
        @list = unpack('nn',$headerdata);
        debug(2,"DEBUG: offset ",$offset,"=",sprintf("0x%04x",$list[0]),
            " offset ",$offset+2,"=",sprintf("0x%04x",$list[1]))
            if($list[0] || $list[1]);
        $offset += 4;
    }

    foreach my $key (sort keys %header)
    {
        debug(2,'DEBUG: ereader{',$key,'}=0x',sprintf("%04x",$header{$key}));
#            if($header{$key});
    }

    $$self{header} = \%header;
    return %header;
}


################################
########## PROCEDURES ##########
################################

=head1 PROCEDURES

=head2 C<cp1252_to_pml()>

An unfinished and completely nonfunctional procedure to convert
Windows-1252 characters to PML \a codes.

DO NOT USE.

=cut

sub cp1252_to_pml
{
    my $text = shift;
    my $subname = ( caller(0) )[3];
    debug(2,"DEBUG[",$subname,"]");

    return unless(defined $text);

    my %cppml = (
        "\x{92}" => '\a146',
        );

    foreach my $char (keys %cppml)
    {
        $text =~ s/$char/$cppml{$char}/gx;
    }
    return $text;
}


=head2 C<pml_to_html($text,$filebase)>

Takes as input a text string in Windows-1252 encoding containing PML
markup codes and returns a string with those codes converted to UTF-8
HTML.

Requires a second argument C<$filebase> to specify the basename of the
file (or specifically, the basename of the file to which output text
will be written) so that image links can be generated correctly.

=cut

sub pml_to_html
{
    my $text = shift;
    my $filebase = shift;
    my $subname = ( caller(0) )[3];
    debug(2,"DEBUG[",$subname,"]");

    return unless(defined $text);
    $text = decode('Windows-1252',$text);

    # Font markers can be terminated by a \n as well as their own
    # code.
    $text =~ s#\\l (.*?) (?:\\l|\\n)
              #<div style="font-size: 120%">$1</div>#gsx;
    $text =~ s#\\n (.*?) \\n
              #<div style="font-size: 100%">$1</div>#gsx;
    $text =~ s#\\s (.*?) (?:\\s|\\n)
              #<div style="font-size: 80%">$1</div>#gsx;

    my %pmlcodes = (
        '\p' => '<br style="page-break-after: always" />\n',
        '\x' => [ '<h1 style="page-break-before: always">','</h1>\n' ],
        '\X0' => [ '<h1>','</h1>\n' ],
        '\X1' => [ '<h2>','</h2>\n' ],
        '\X2' => [ '<h3>','</h3>\n' ],
        '\X3' => [ '<h4>','</h4>\n' ],
        '\X4' => [ '<h5>','</h5>\n' ],
        '\C0=' => '<div class="C0"></div>',
        '\C1=' => '<div class="C1"></div>',
        '\C2=' => '<div class="C2"></div>',
        '\C3=' => '<div class="C3"></div>',
        '\C4=' => '<div class="C4"></div>',
        '\c' => [ '<div style="text-align: center">','</div>' ],
        '\r' => [ '<div style="text-align: right">','</div>' ],
        '\i' => [ '<em>','</em>' ],
        '\u' => [ '<ul>','</ul>' ],
        '\o' => [ '<strike>','</strike>' ],
        '\v' => [ '<!-- ',' -->' ],
        '\t' => [ '<ul>','</ul>' ],
        '\T=' => '',
        '\b' => [ '<b>','</b>' ],
        '\B' => [ '<strong>','</strong>' ],
        '\Sb' => [ '<sub>','</sub>' ],
        '\Sp' => [ '<sup>','</sup>' ],
        # font-variant: small-caps is very badly supported on most
        # browsers, so using a workaround.
        # '\k' => [ '<div style="font-variant: small-caps">','</div>' ],
        '\k' => [ '<div style="font-size: smaller; text-transform: uppercase;">',
                  '</div>' ],
        "\\\\" => "\\",
        '\-' => '',
        '\I' => [ '<div class="refindex">','</div>' ],
        );

    # Convert newlines followed by at least two spaces to <p>
    $text =~ s#\n(\s{2,})(.*?)(?=\n)
              #<p>$2</p>#gosx;

    # Convert remaining newlines to <br />
    $text =~ s#\n(.*?)\n
              #\n<br />$1<br />\n#gsx;

    # Reinsert newlines on <p> and <br> tags
    $text =~ s#(<p>)#\n$1#g;
    $text =~ s#(<br />)#$1\n#g;


    # Handle simple tag replacements
    while(my ($pmlcode,$replacement) = each(%pmlcodes) )
    {
        if(ref $replacement eq 'ARRAY')
        {
            if($pmlcode =~ / = $/x)
            {
                # This doesn't work?  Need to rewrite for RHS eval?
                $pmlcode =~ s/= $//x;
                $text =~ s#\Q$pmlcode\E
                           ="(.*?)" (.*?) \Q $pmlcode \E
                          #$replacement->[0]$2$replacement->[1]#gsx;
            }
            else
            {
                $text =~ s#\Q$pmlcode\E (.*?) \Q$pmlcode\E
                          #$replacement->[0]$1$replacement->[1]#gsx;
            }
        }
        else
        {
            if($pmlcode =~ / = $/x)
            {
                $text =~ s#\Q$pmlcode\E "(.*?)"
                          #$replacement#gsx;
            }
            else
            {
                $text =~ s#\Q$pmlcode\E
                          #$replacement#gsx;
            }

        }
    } # while(my ($pmlcode,$replacement) = each(%pmlcodes) )

    # Strip leftover \n codes
    $text =~ s#\\n
              ##gsx;

    # Horizontal rules
    $text =~ s!\\w="(.*?)"
              !<hr width="$1" />!gsx;

    # Images
    $text =~ s!\\m="(.*?)"
              !<img src="${filebase}_img/$1" />!gsx;

    # Anchors and references
    $text =~ s!\\q="(.*?)"(.*?)\\q
              !<a href="#$1">$2</a>!gsx;
    $text =~ s!\\Q="(.*?)"
              !<a id="$1"></a>!gsx;

    # Footnotes and sidebars
    $text =~ s!\\Fn="(.*?)"(.*?)\\Fn
              !<a id="$1-ref" href="#$1">$2</a>!gsx;
    $text =~ s!\\Sd="(.*?)"(.*?)\\Sd
              !<a id="$1-ref" href="#$1">$2</a>!gsx;

    # Double-newlines after page breaks
    $text =~ s#("page-break-after: always" />)#$1\n\n#g;

    return $text;
}

########## END CODE ##########

=head1 BUGS AND LIMITATIONS

=over

=item * HTML conversion doesn't handle handle the \T command used to
        indent.

=item * HTML conversion may be suboptimal in many ways.

Most notably, most linebreaks are handled as <br />, and without any
heed to whether those linebreaks occur inside of some other element.
Validation is extremely unlikely.

=back

=head1 AUTHOR

Zed Pobre <zed@debian.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2008 Zed Pobre

Licensed to the public under the terms of the GNU GPL, version 2

=cut

1;
