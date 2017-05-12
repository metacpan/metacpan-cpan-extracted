package EBook::Tools::Unpack;
use warnings; use strict; use utf8;
use English qw( -no_match_vars );
use version 0.74; our $VERSION = qv("0.5.0");

# Perl Critic overrides:
## no critic (Package variable)
# RequireBriefOpen seems to be way too brief to be useful
## no critic (RequireBriefOpen)
# Builtin homonyms are methods and flagged as such
## no critic (ProhibitBuiltinHomonyms)
# Double-sigils are needed for lexical filehandles in clear print statements
## no critic (Double-sigil dereference)

=head1 NAME

EBook::Tools::Unpack - Object class for unpacking e-book files into their component parts and metadata

=head1 SYNOPSIS

 use EBook::Tools::Unpack;
 my $unpacker = EBook::Tools::Unpack->new(
    'file'     => $filename,
    'dir'      => $dir,
    'encoding' => $encoding,
    'format'   => $format,
    'raw'      => $raw,
    'author'   => $author,
    'title'    => $title,
    'opffile'  => $opffile,
    'tidy'     => $tidy,
    'nosave'   => $nosave,
    );
 $unpacker->unpack;

or, more simply:

 use EBook::Tools::Unpack;
 my $unpacker = EBook::Tools::Unpack->new('file' => 'mybook.prc');
 $unpacker->unpack;

=cut

require Exporter;
use base qw(Exporter);

our @EXPORT_OK;
@EXPORT_OK = qw (
    );

use Archive::Zip qw(:ERROR_CODES);
use Carp;
use EBook::Tools qw(:all);
use EBook::Tools::EReader qw(:all);
use EBook::Tools::IMP qw(:all);
use EBook::Tools::Mobipocket qw(:all);
use EBook::Tools::MSReader qw(:all);
use EBook::Tools::PalmDoc qw(uncompress_palmdoc);
use Encode;
use Fcntl qw(SEEK_CUR SEEK_SET);
use File::Basename qw(dirname fileparse);
use File::Path;     # Exports 'mkpath' and 'rmtree'
use File::Which;    # Exports 'which'
binmode(STDERR,':encoding(UTF-8)');

my $drmsupport = 0;
eval
{
    require EBook::Tools::DRM;
    EBook::Tools::DRM->import();
}; # Trailing semicolon is required here
unless($@){ $drmsupport = 1; }


our %palmdbcodes = (
    '.pdfADBE' => 'adobereader',
    'TEXtREAd' => 'palmdoc',
    'BVokBDIC' => 'bdicty',
    'DB99DBOS' => 'db',
    'PNPdPPrs' => 'ereader',
    'PNRdPPrs' => 'ereader',
    'vIMGView' => 'fireviewer',
    'PmDBPmDB' => 'handbase',
    'InfoINDB' => 'infoview',
    'ToGoToGo' => 'isilo1',
    'SDocSilX' => 'isilo3',
    'JbDbJBas' => 'jfile',
    'JfDbJFil' => 'jfilepro',
    'DATALSdb' => 'list',
    'Mdb1Mdb1' => 'mobiledb',
    'BOOKMOBI' => 'mobipocket',
    'DataPlkr' => 'plucker',
    'DataSprd' => 'quicksheet',
    'SM01SMem' => 'supermemo',
    'TEXtTlDc' => 'tealdoc',
    'InfoTlIf' => 'tealinfo',
    'DataTlMl' => 'tealmeal',
    'DataTlPt' => 'tealpaint',
    'dataTDBP' => 'thinkdb',
    'TdatTide' => 'tides',
    'ToRaTRPW' => 'tomeraider',
    'BDOCWrdS' => 'wordsmith',
    'zTXTGPlm' => 'ztxt',
    );

our %pdbcompression = (
    1 => 'no compression',
    2 => 'PalmDoc compression',
    17480 => 'Mobipocket DRM',
    );


#################################
########## CONSTRUCTOR ##########
#################################

=head1 CONSTRUCTOR

=head2 C<new(%args)>

Instantiates a new Ebook::Tools::Unpack object.

=head3 Arguments

=over

=item * C<file>

The file to unpack.  Specifying this is mandatory.

=item * C<dir>

The directory to unpack into.  If not specified, defaults to the
basename of the file.

=item * C<encoding>

If specified, overrides the encoding to use when unpacking.  This is
normally detected from the file and does not need to be specified.

Valid values are '1252' (specifying Windows-1252) and '65001'
(specifying UTF-8).

=item * C<htmlconvert>

If set to true, an attempt will be made to convert non-HTML output
text to HTML where possible.

=item * C<key>

The decryption key to use if necessary (not yet implemented)

=item * C<keyfile>

The file holding the decryption keys to use if necessary (not yet
implemented)

=item * C<language>

If specified, overrides the detected language information.

=item * C<opffile>

The name of the file in which the metadata will be stored.  If not
specified, defaults to C<content.opf>.

=item * C<raw>

If set true, this forces no corrections to be done on any extracted
text and a lot of raw, unparsed, unmodified data to be dumped into the
directory along with everything else.  It's useful for debugging
exactly what was in the file being unpacked, and (when combined with
C<nosave>) reducing the time needed to extract parsed data from an
ebook container without actually unpacking it.

=item * C<author>

Overrides the detected author name.

=item * C<title>

Overrides the detected title.

=item * C<tidy>

If set to true, the unpacker will run tidy on any HTML output files to
convert them to valid XHTML.  Be warned that this can occasionally
change the formatting, as Tidy isn't very forgiving on certain common
tricks (such as empty <pre> elements with style elements) that abuse
the standard.

=item * C<nosave>

If set to true, the unpacker will run through all of the unpacking
steps except those that actually write to the disk.  This is useful
for testing, but also (particularly when combined with C<raw>) can be
used for extracting parsed data from an ebook container without
actually unpacking it.

=back

=cut

my @fields = (
    'file',
    'dir',
    'encoding',
    'format',
    'formatinfo',
    'htmlconvert',
    'raw',
    'key',
    'keyfile',
    'opffile',
    'author',
    'language',
    'title',
    'datahashes',
    'detected',
    'tidy',
    'nosave',
    );

require fields;
fields->import(@fields);

sub new   ## no critic (Always unpack @_ first)
{
    my $self = shift;
    my (%args) = @_;
    my $class = ref($self) || $self;
    my $subname = (caller(0))[3];
    debug(2,"DEBUG[",$subname,"]");

    my %valid_args = (
        'file' => 1,
        'dir' => 1,
        'encoding' => 1,
        'key' => 1,
        'keyfile' => 1,
        'format' => 1,
        'htmlconvert' => 1,
        'raw' => 1,
        'author' => 1,
        'language' => 1,
        'title' => 1,
        'opffile' => 1,
        'tidy' => 1,
        'nosave' => 1,
        );
    foreach my $arg (keys %args)
    {
        croak($subname,"(): invalid argument '",$arg,"'")
            if(!$valid_args{$arg});
    }
    croak($subname,"(): no input file specified")
        unless($args{file});
    croak($subname,"(): '",$args{file},"' not found")
        unless(-f $args{file});

    $self = fields::new($class);
    $self->{file} = $args{file};
    $self->{dir} = $args{dir} || $self->filebase;
    $self->{encoding} = $args{encoding};
    $self->{format} = $args{format} if($args{format});
    $self->{key} = $args{key} if($args{key});
    $self->{keyfile} = $args{keyfile} if($args{keyfile});
    $self->{opffile} = $args{opffile} || "content.opf";
    $self->{author} = $args{author} if($args{author});
    $self->{title} = $args{title} if($args{title});
    $self->{datahashes} = {};
    $self->{detected} = {};
    $self->{htmlconvert} = $args{htmlconvert};
    $self->{raw} = $args{raw};
    $self->{tidy} = $args{tidy};
    $self->{nosave} = $args{nosave};

    $self->detect_format unless($self->{format});
    return $self;
}


=head1 ACCESSOR METHODS

See L</new()> for more details on what some of these mean.  Note
that some values cannot be autodetected until an unpack method
executes.

=head2 C<author>

=head2 C<dir>

=head2 C<file>

=head2 C<filebase>

In scalar context, this is the basename of C<file>.  In list context,
it actually returns the basename, directory, and extension as per
C<fileparse> from L<File::Basename>.

=head2 C<format>

=head2 C<key>

=head2 C<keyfile>

=head2 C<language>

This returns the language specified by the user, if any.  It remains
undefined if the user has not requested that a language code be set
even if a language was autodetected.

=head2 C<opffile>

=head2 C<raw>

=head2 C<title>

This returns the title specified by the user, if any.  It remains
undefined if the user has not requested a title be set even if a title
was autodetected.

=head2 C<detected>

This returns a hash containing the autodetected metadata, if any.

=cut

sub author :method
{
    my $self = shift;
    return $$self{author};
}

sub dir :method
{
    my $self = shift;
    return $$self{dir};
}

sub file :method
{
    my $self = shift;
    return $$self{file};
}

sub filebase :method
{
    my $self = shift;
    return fileparse($$self{file},'\.\w+$');
}

sub format :method
{
    my $self = shift;
    return $$self{format};
}

sub key :method
{
    my $self = shift;
    return $$self{key};
}

sub keyfile :method
{
    my $self = shift;
    return $$self{keyfile};
}

sub language :method
{
    my $self = shift;
    return $$self{language};
}

sub opffile :method
{
    my $self = shift;
    return $$self{opffile};
}

sub raw :method
{
    my $self = shift;
    return $$self{raw};
}

sub title :method
{
    my $self = shift;
    return $$self{title};
}

sub detected :method
{
    my $self = shift;
    return $$self{detected};
}


=head1 MODIFIER METHODS

=head2 C<detect_format()>

Attempts to automatically detect the format of the input file and set
the internal object attributes C<< $self->{format} >> and
C<< $self->{formatinfo} >>, where the former is a one-word string used by
the dispatcher to select the correct unpacking method and the latter
may contain additional detected information (such as a title or
version).

Croaks if detection fails.

In scalar context, returns C<< $self->{format} >>.  In list context,
returns the two element list C<< ($self->{format},$self->{formatinfo}) >>

This is automatically called by L</new()> if the C<format> argument is
not specified.

=cut

sub detect_format :method
{
    my $self = shift;
    my $subname = ( caller(0) )[3];
    my $filename = $$self{file};
    my $fh;
    my $headerdata;
    my $ident;
    my $info;
    my $index;
    debug(2,"DEBUG[",$subname,"]");

    open($fh,"<",$filename)
        or croak($subname,"(): failed to open '",$filename,"' for reading!\n");
    sysread($fh,$headerdata,68);
    close($fh)
        or croak($subname,"(): failed to close '",$filename,"'!\n");

    # Check for PalmDB identifiers
    $ident = substr($headerdata,60,8);
    debug(3,"DEBUG: PalmDB ident = '$ident'");
    if($palmdbcodes{$ident})
    {
        $$self{format} = $palmdbcodes{$ident};
        $info = substr($headerdata,0,32);
        $index = index($info,"\0");
        if($index < 0)
        {
            debug(0,"WARNING: detected header in '",$filename,
                  "' is not null-terminated.");
        }
        else
        {
            $info = substr($info,0,$index);
        }
        debug(1,"DEBUG: Autodetected book format '",$$self{format},
              "', info '",$info,"'");
        $$self{formatinfo} = $info;
        # The info here is always the title, but there may be better
        # ways of extracting it later.
        $$self{detected}{title} = $info;
    }

    # Check for Microsoft Reader
    $ident = substr($headerdata,0,8);
    debug(3,"DEBUG: MS Reader ident = '$ident'");
    if($ident eq 'ITOLITLS')
    {
        $$self{format} = 'msreader';
        $$self{formatinfo} = unpack("c",substr($headerdata,8,1));
        debug(1,"DEBUG: Autodetected book format '",$$self{format},
              "', version ",$$self{formatinfo});
    }

    # Check for ePub
    $ident = substr($headerdata,30,28);
    $info = substr($headerdata,0,2);
    if($ident eq 'mimetypeapplication/epub+zip'
       && $info eq 'PK')
    {
        $$self{format} = 'epub';
        $$self{formatinfo} = '';
        debug(1,"DEBUG: autodetected book format '",$$self{format},"'");
    }

    # Check for .IMP
    $ident = substr($headerdata,2,8);
    $info = unpack('n',substr($headerdata,0,2));
    if($ident eq 'BOOKDOUG')
    {
        $$self{format} = 'imp';
        $$self{formatinfo} = $info;
        debug(1,"DEBUG: autodetected book format '",$$self{format},
              "' version ",$$self{formatinfo});
    }

    # Check for miscellaneous zip archive (OEBZip?)
    $ident = substr($headerdata,0,4);
    if($ident eq "PK\x{03}\x{04}")
    {
        $$self{format} = 'ziparchive';
        $$self{formatinfo} = unpack('c',substr($headerdata,4,1)) / 10;
        debug(1,"DEBUG: autodetected book format '",$$self{format},
              "', version ",$$self{formatinfo});
    }

    croak($subname,"(): unable to determine book format")
        unless($$self{format});

    if(wantarray) { return ($$self{format},$$self{formatinfo}); }
    else { return $$self{format}; }
}


=head2 C<detect_from_mobi_exth()>

Detects metadata values from the MOBI EXTH headers retrieved via
L</unpack_mobi_exth()> and places them into the C<detected> attribute.

=cut

sub detect_from_mobi_exth :method
{
    my $self = shift;
    my $subname = ( caller(0) )[3];
    debug(2,"DEBUG[",$subname,"]");

    my @mobiexth;
    if(defined $self->{datahashes}{mobiexth})
    {
        @mobiexth = @{$self->{datahashes}{mobiexth}};
    }
    my $data;
    my %exthtypes = %EBook::Tools::Mobipocket::exthtypes;
    my %exth_is_int = %EBook::Tools::Mobipocket::exth_is_int;
    my %exth_repeats = %EBook::Tools::Mobipocket::exth_repeats;

    # EXTH records
    foreach my $exth (@mobiexth)
    {
        my $type = $exthtypes{$$exth{type}};
        unless($type)
        {
            carp($subname,"(): unknown EXTH record type ",$$exth{type});
            next;
        }
        if($exth_is_int{$$exth{type}})
        {
            $data = '0x' . hexstring($$exth{data});
        }
        else
        {
            $data = $$exth{data};
        }

        if($exth_repeats{$$exth{type}})
        {
            debug(2,"DEBUG: Repeating EXTH ",$type," = '",$data,"'");
            my @extharray = ();
            my $oldexth = $$self{detected}{$type};
            if(ref $oldexth eq 'ARRAY') { @extharray = @$oldexth; }
            elsif($oldexth) { push(@extharray,$oldexth); }
            push(@extharray,$data);
            $$self{detected}{$type} = \@extharray;
        }
        else
        {
            debug(2,"DEBUG: Single EXTH ",$type," = '",$data,"'");
            $$self{detected}{$type} = $data;
        }
    }

    return 1;
}


=head2 C<gen_opf(%args)>

This generates an OPF file from detected and specified metadata.  It
does not honor the C<nosave> flag, and will always write its output.

Normally this is called automatically from inside the C<unpack>
methods, but can be called manually after an unpack if the C<nosave>
flag was set to write an OPF anyway.

Returns the filename of the OPF file.

=head3 Arguments

=over

=item * C<opffile> (optional)

If specified, this overrides the object attribute C<opffile>, and
determines the filename to use for the generated OPF file.  If not
specified, and the object attribute C<opffile> has somehow been
cleared (the attribute is set during L</new()>), it will be generated
by looking at the C<textfile> argument.  If no value can be found, the
method croaks.  If a value was found somewhere other than the object
attribute C<opffile>, then the object attribute is updated to match.

=item * C<textfile> (optional)

The file containing the main text of the document.  If specified, the
method will attempt to split metadata out of the file and add whatever
remains to the manifest of the OPF.

=item * C<mediatype> (optional)

The media type (mime type) of the document specified via C<textfile>.
If C<textfile> is not specified, this argument is ignored.  If C<textfile> is specified, but

=back

=cut

sub gen_opf :method   ## no critic (Always unpack @_ first)
{
    my $self = shift;
    my (%args) = @_;
    my $subname = ( caller(0) )[3];
    debug(2,"DEBUG[",$subname,"]");
    my %valid_args = (
        'opffile' => 1,
        'textfile' => 1,
        'mediatype' => 1,
        );
    foreach my $arg (keys %args)
    {
        croak($subname,"(): invalid argument '",$arg,"'")
            if(!$valid_args{$arg});
    }
    my $ebook = EBook::Tools->new();
    my $textfile = $args{textfile};
    my $opffile = $args{opffile} || $$self{opffile};
    my $mediatype = $args{mediatype};
    unless($self->{raw})
    {
        $opffile = split_metadata($textfile,$opffile) if($textfile);
    }
    my $detected;
    my $code;
    my $index;

    croak($subname,"(): could not determine OPF filename\n")
        unless($opffile);
    $$self{opffile} ||= $opffile;

    if(-f $opffile)
    {
        $ebook->init($opffile);
    }
    else
    {
        $ebook->init_blank(opffile => $opffile,
                           title => $$self{title},
                           author => $$self{author});
    }
    $ebook->fix_metastructure_oeb12();
    $ebook->add_document($textfile,'text-main',$mediatype) if($textfile);

    # Set author, title, and opffile from manual overrides
    $ebook->set_primary_author(text => $$self{author}) if($$self{author});
    $ebook->set_title(text => $$self{title}) if($$self{title});
    $ebook->set_opffile($$self{opffile}) if($$self{opffile});

    # If we still don't have author or title, set it from the best
    # extraction we have
    $ebook->set_primary_author(text => $$self{detected}{author})
        if(!$$self{author} && $$self{detected}{author});
    $ebook->set_title(text => $$self{detected}{title})
        if(!$$self{title} && $$self{detected}{title});

    # Set the language codes
    $ebook->set_language(text => $$self{detected}{language})
        if($$self{detected}{language});
    $ebook->set_metadata(gi => 'DictionaryInLanguage',
                         text => $$self{detected}{dictionaryinlanguage})
        if($$self{detected}{dictionaryinlanguage});
    $ebook->set_metadata(gi => 'DictionaryOutLanguage',
                         text => $$self{detected}{dictionaryoutlanguage})
        if($$self{detected}{dictionaryoutlanguage});


    # Set the remaining autodetected metadata, some of which may or
    # may not be in array form
    $detected = $$self{detected}{contributor};
    if( $detected && (ref($detected) eq 'ARRAY') )
    {
        foreach my $text (@$detected)
        {
            $ebook->add_metadata(gi => 'dc:Contributor',
                                 parent => 'dc-metadata',
                                 text => $text);
        }
    }
    elsif($detected)
    {
        $ebook->add_metadata(gi => 'dc:Contributor',
                             parent => 'dc-metadata',
                             text => $detected);
    }

    $detected = $$self{detected}{publisher};
    if( $detected && (ref($detected) eq 'ARRAY') )
    {
        foreach my $text (@$detected)
        {
            $ebook->add_metadata(gi => 'dc:Publisher',
                                 parent => 'dc-metadata',
                                 text => $text);
        }
    }
    elsif($detected)
    {
        $ebook->set_publisher(text => $detected);
    }

    $ebook->set_description(text => decode_utf8($$self{detected}{description}))
        if($$self{detected}{description});

    $detected = $$self{detected}{isbn};
    if( $detected && (ref($detected) eq 'ARRAY') )
    {
        foreach my $text (@$detected)
        {
            $ebook->add_identifier(text => $text,
                                   scheme => 'ISBN')
        }
    }
    elsif($detected)
    {
        $ebook->add_identifier(text => $detected,
                               scheme => 'ISBN')
    }

    $detected = $$self{detected}{subject};
    if( $detected && (ref($detected) eq 'ARRAY') )
    {
        debug(2,"Multiple dc:Subject entries");
        $index = 0;
        foreach my $text (@$detected)
        {
            $code = @{$$self{detected}{subjectcode}}[$index];
            $ebook->add_subject(text => $text,
                                basiccode => $code);
            $index++;
        }
    }
    elsif($detected)
    {
        debug(2,"Single dc:Subject entry");
        $code = $$self{detected}{subjectcode};
        $ebook->add_subject(text => $$self{detected}{subject},
                            basiccode => $code)
    }

    $ebook->set_date(text => $$self{detected}{publicationdate},
                     event => 'publication')
        if($$self{detected}{publicationdate});
    $ebook->set_rights(text => $$self{detected}{rights})
        if($$self{detected}{rights});
    $ebook->set_type(text => $$self{detected}{type})
        if($$self{detected}{type});
    $ebook->set_adult($$self{detected}{adult})
        if($$self{detected}{adult});
    $ebook->set_review(text => decode_utf8($$self{detected}{review}))
        if($$self{detected}{review});
    $ebook->set_retailprice(text => $$self{detected}{retailprice},
                            currency => $$self{detected}{currency})
        if($$self{detected}{retailprice});

    # Automatically clean up any mess
    $ebook->fix_misc;
    $ebook->fix_oeb12;
    $ebook->fix_mobi;
    unlink($opffile);
    $ebook->save;
    return 1;
}


=head2 C<unpack()>

This is a dispatcher for the specific unpacking methods needed to
unpack a particular format.  Unless you feel a need to override the
unpacking method specified or detected during object construction, it
is probalby better to call this than the specific unpacking methods.

=cut

sub unpack :method
{
    my $self = shift;
    my $subname = ( caller(0) )[3];
    debug(2,"DEBUG[",$subname,"]");

    my $filename = $$self{file};
    croak($subname,"(): no input file specified\n")
        unless($filename);
    my $retval;

    my  %unpack_dispatch = (
        'ereader'    => \&unpack_ereader,
        'imp'        => \&unpack_imp,
        'mobipocket' => \&unpack_mobi,
        'msreader'   => \&unpack_msreader,
        'palmdoc'    => \&unpack_palmdoc,
        'aportisdoc' => \&unpack_palmdoc,
        'ziparchive' => \&unpack_zip,
        );

    croak($subname,
          "(): don't know how to handle format '",$$self{format},"'\n")
        if(!$unpack_dispatch{$$self{format}});
    $retval = $unpack_dispatch{$$self{format}}->($self);
    return $retval;
}


=head2 C<unpack_ereader()>

Unpacks Fictionwise/PeanutPress eReader (-er.pdb) files.

=cut

sub unpack_ereader :method
{
    my $self = shift;
    my $subname = ( caller(0) )[3];
    debug(2,"DEBUG[",$subname,"]");

    my $pdb = EBook::Tools::EReader->new();
    my $textname;

    $pdb->Load($$self{file});

    $$self{datahashes}{ereader} = $pdb->{header};
    $$self{detected}{title}     = decode('Windows-1252',$pdb->{title});
    $$self{detected}{author}    = decode('Windows-1252',$pdb->{author});
    $$self{detected}{rights}    = decode('Windows-1252',$pdb->{rights});
    $$self{detected}{publisher} = decode('Windows-1252',$pdb->{publisher});
    $$self{detected}{isbn}      = decode('Windows-1252',$pdb->{isbn});
    debug(1,"DEBUG: PDB title: '",$$self{detected}{title},"'");
    debug(1,"DEBUG: PDB author: '",$$self{detected}{author},"'");
    debug(1,"DEBUG: PDB copyright: '",$$self{detected}{rights},"'");
    debug(1,"DEBUG: PDB publisher: '",$$self{detected}{publisher},"'");
    debug(1,"DEBUG: PDB ISBN: '",$$self{detected}{isbn},"'");

    unless($$self{nosave})
    {
        my $cwd = usedir($self->{dir});
        $pdb->write_images;
        $pdb->write_unknown_records if($$self{raw});
        if($$self{htmlconvert})
        {
            $textname = $pdb->write_html();
            $self->gen_opf(textfile => $textname,
                           mediatype => 'application/xhtml+xml');
        }
        else
        {
            $textname = $pdb->write_pml();
            $self->gen_opf(textfile => $textname,
                           mediatype => 'text/plain');
        }
        chdir($cwd);
    }
    return 1;
}


=head2 C<unpack_imp()>

Unpacks SoftBook/GEB/REB/eBookWise (.imp) files.

=cut

sub unpack_imp
{
    my $self = shift;
    my $subname = ( caller(0) )[3];
    debug(2,"DEBUG[",$subname,"]");

    my $imp = EBook::Tools::IMP->new();
    $imp->load($self->{file});

    $self->{detected}->{author} = $imp->author;
    $self->{detected}->{title} = $imp->title;

    if($self->{raw})
    {
        $imp->write_resdir();
    }

    $imp->write_text(dir => $self->{dir});
    $imp->write_images(dir => $self->{dir});

    print {*STDERR} "WARNING: IMP support not yet functional!\n";
    return 0;
}


=head2 C<unpack_mobi()>

Unpacks Mobipocket (.prc / .mobi) files.

=cut

sub unpack_mobi :method
{
    my $self = shift;
    my $subname = ( caller(0) )[3];
    debug(2,"DEBUG[",$subname,"]");

    my $mobi = EBook::Tools::Mobipocket->new();
    my @records;
    my $data;
    my $opffile;

    # Used for extracting images
    my $imageid = 0;
    my $firstimagerec = 0;

    # Used for file output
    my $htmlname;

    my $reccount = 0; # The Record ID cannot be reliably used to identify
                      # the first record.  This increments as each
                      # record is examined

    $mobi->Load($$self{file});

    @records = @{$mobi->{records}};
    croak($subname,"(): no pdb records found!") unless(@records);

    $$self{datahashes}{palm} = $mobi->{header}{palm};
    $$self{datahashes}{mobi} = $mobi->{header}{mobi};
    $$self{datahashes}{mobiexth} = $mobi->{header}{exth};
    $$self{encoding}
    = $$self{datahashes}{mobi}{encoding} unless($$self{encoding});
    $$self{detected}{title} = $mobi->{title};
    $$self{detected}{language} = $mobi->{header}{mobi}{language};
    $$self{detected}{dictionaryinlanguage}
    = $mobi->{header}{mobi}{dilanguage};
    $$self{detected}{dictionaryoutlanguage}
    = $mobi->{header}{mobi}{dolanguage};

    $self->detect_from_mobi_exth();
    if($self->{detected}->{title}) {
        $htmlname = clean_filename($self->{detected}->{title} . ".html");
    }
    else {
        $htmlname = clean_filename($self->filebase . ".html");
    }

    if($$self{raw} && !$$self{nosave})
    {
        $mobi->write_unknown_records();
    }

    croak($subname,"(): found no text in '",$$self{file},"'!")
        unless($mobi->{text});

    $mobi->fix_html(filename => $htmlname) unless($$self{raw});

    unless($$self{nosave})
    {
        my $cwd = usedir($self->{dir});
        $mobi->write_text($htmlname);
        $mobi->write_images();
        $self->gen_opf(textfile => $htmlname);

        if($$self{tidy})
        {
            debug(1,"Tidying '",$htmlname,"'");
            system_tidy_xhtml($htmlname);
        }
        chdir($cwd);
    }
    return 1;
}


=head2 C<unpack_msreader()>

Unpacks Microsoft Reader (.lit) files

=cut

sub unpack_msreader :method
{
    my $self = shift;
    my $subname = ( caller(0) )[3];
    debug(2,"DEBUG[",$subname,"]");

    my $convertlit = find_convertlit();
    my $keys = find_convertlit_keys($$self{file});

    my $retval = system_convertlit(infile => $$self{file},
                                   keyfile => $keys,
                                   dir => $$self{dir});
    return $retval;
}


=head2 C<unpack_palmdoc()>

Unpacks PalmDoc / AportisDoc (.pdb) files

=cut

sub unpack_palmdoc :method
{
    my $self = shift;
    my $subname = ( caller(0) )[3];
    debug(2,"DEBUG[",$subname,"]");

    my $filename = $$self{file};

    my $ebook = EBook::Tools->new();
    my $pdb = EBook::Tools::PalmDoc->new();
    my ($outfile,$bookmarkfile,$fh);
    my %bookmarks;
    $bookmarkfile = $self->filebase . "-bookmarks.txt";

    $pdb->Load($filename);
    debug(2,"DEBUG: PalmDoc Name: ",$pdb->{'name'});
    debug(2,"DEBUG: PalmDoc Version: ",$pdb->{'version'});
    debug(2,"DEBUG: PalmDoc Type: ",$pdb->{'type'});
    debug(2,"DEBUG: PalmDoc Creator: ",$pdb->{'creator'});

    $$self{title}   ||= $pdb->{'name'};
    $$self{author}  ||= 'Unknown Author';
    $$self{opffile} ||= $$self{title} . ".opf";

    unless($$self{nosave})
    {
        usedir($self->{dir});
        if($$self{htmlconvert})
        {
            $outfile = $self->filebase . ".html";
            open($fh,'>:encoding(UTF-8)',$outfile)
                or croak($subname,"(): unable to open '",$outfile,
                         "' for writing!\n");
            print {*$fh} $pdb->html;
            close($fh)
                or croak("Failed to close '",$outfile,"'!");
        }
        else
        {
            $outfile = $self->filebase . ".txt";
            open($fh,">:raw",$outfile)
                or croak("Failed to open '",$outfile,"' for writing!");
            print {*$fh} $pdb->text;
            close($fh)
                or croak("Failed to close '",$outfile,"'!");
        }

        open($fh,">:raw",$bookmarkfile)
            or croak("Failed to open '",$bookmarkfile,"' for writing!");
        %bookmarks = $pdb->bookmarks;
        if(%bookmarks)
        {
            foreach my $offset (sort {$a <=> $b} keys %bookmarks)
            {
                print {*$fh} $offset,"\t",$bookmarks{$offset},"\n";
            }
            close($fh)
                or croak("Failed to close '",$bookmarkfile,"'!");
        }

        $ebook->init_blank(opffile => $$self{opffile},
                           title => $$self{title},
                           author => $$self{author});
        $ebook->add_document($outfile,'text-main');
        $ebook->save;
    }
    return $$self{opffile};
}


=head2 C<unpack_zip()>

Unpacks Zip archives (including ePub files).

=cut

sub unpack_zip :method
{
    my $self = shift;
    my $subname = ( caller(0) )[3];
    debug(2,"DEBUG[",$subname,"]");

    unless($self->{nosave})
    {
        my $cwd = usedir($self->{dir});

        if (which('unzip')) {
            my @syscmd = ( 'unzip', '-q', $cwd . '/' . $self->{file} );
            system(@syscmd);
            system_result($subname,$CHILD_ERROR,@syscmd);
        }
        else {
            my $zip = Archive::Zip->new();
            my $status = $zip->read($cwd.'/'.$self->{file});
            if ($status != AZ_OK) {
                croak($subname,'(): error while parsing zip file "',$self->{file},'" (',$status,')!');
            }

            $status = $zip->extractTree(undef);
            if ($status != AZ_OK) {
                croak($subname,'(): error while extracting zip file "',$self->{file},'" (',$status,')!');
            }
        }
        chdir($cwd);
    }
    return 1;
}


########## PROCEDURES ##########

# No procedures


########## END CODE ##########

=head1 BUGS AND LIMITATIONS

=over

=item * DRM isn't handled.  Infrastructure to support this via an
external plug-in module may eventually be built, but it will never
become part of the main module for legal reasons.

=item * Unit tests are incomplete

=item * Documentation is incomplete.  Accessors in particular could
use some cleaning up.

=item * Need to implement setter methods for object attributes

=item * Import/extraction/unpacking is currently limited to PalmDoc,
Mobipocket, and eReader.  Extraction from Microsoft Reader (.lit) and
ePub is also eventually planned.  Other formats may follow from there.

=back

=head1 AUTHOR

Zed Pobre <zed@debian.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2008 Zed Pobre

Licensed to the public under the terms of the GNU GPL, version 2

=cut

1;
__END__

