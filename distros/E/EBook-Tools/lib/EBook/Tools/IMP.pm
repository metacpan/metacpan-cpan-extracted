package EBook::Tools::IMP;
use warnings; use strict; use utf8;
use English qw( -no_match_vars );
use version 0.74; our $VERSION = qv("0.5.0");

## Perl Critic overrides:
# RequireBriefOpen seems to be way too brief to be useful
## no critic (RequireBriefOpen)
# We're not interpolating constants and not making them lexical makes identifying them easier
## no critic (ProhibitConstantPragma)

=head1 NAME

EBook::Tools::IMP - Object class for manipulating the SoftBook/GEB/REB/eBookWise C<.IMP> and C<.RES> e-book formats

=head1 SYNOPSIS

 use EBook::Tools::IMP qw(:all)
 my $imp = EBook::Tools::IMP->new();
 $imp->load('myfile.imp');

=cut

require Exporter;
use base qw(Exporter);

our @EXPORT_OK;
@EXPORT_OK = qw (
    &detect_resource_type
    &parse_imp_resource_v1
    &parse_imp_resource_v2
    );
our %EXPORT_TAGS = ('all' => [@EXPORT_OK]);

use Carp;
use Cwd qw(getcwd realpath);
use EBook::Tools qw(:all);
use EBook::Tools::LZSS qw(:all);
use Encode;
use File::Basename qw(basename dirname fileparse);
use File::Path;     # Exports 'mkpath' and 'rmtree'
use Image::Size;
use List::MoreUtils qw(any none);
binmode(STDERR,':encoding(UTF-8)');

my $drmsupport = 0;
eval
{
    require EBook::Tools::DRM;
    EBook::Tools::DRM->import();
}; # Trailing semicolon is required here
unless($@){ $drmsupport = 1; }


# Constants for $self->{device},
use constant DEVICE_SB200 => 0;         # SoftBook 200/250
use constant DEVICE_REB1200 => 1;       # REB 1200/GEB 2150
use constant DEVICE_EBW1150 => 2;       # EBW 1150/GEB 1150

use constant IMAGETYPES => ('png','jpg','gif','pic');
use constant IMAGERESOURCES => ('GIF ','JPEG','PICT','PIC2','PNG ');
my %IMAGE_RESOURCE_MAP = (
    'GIF ' => 'gif',
    'JPEG' => 'jpg',
    'PICT' => 'pic',
    'PIC2' => 'png',
    'PNG ' => 'png',
    );


####################################################
########## CONSTRUCTOR AND INITIALIZATION ##########
####################################################

my %rwfields = (
    'version'        => 'integer',
    'filename'       => 'string',
    'filecount'      => 'integer',
    'resdirlength'   => 'integer',
    'resdiroffset'   => 'integer',
    'compression'    => 'integer',
    'encryption'     => 'integer',
    'device'         => 'integer',
    'zoomstates'     => 'integer',
    'identifier'     => 'string',
    'category'       => 'string',
    'subcategory'    => 'string',
    'title'          => 'string',
    'lastname'       => 'string',
    'middlename'     => 'string',
    'firstname'      => 'string',
    'etiserverdata'  => 'hash',         # Extra data after book properties
    'resdirname'     => 'string',
    'RSRC.INF'       => 'string',
    'resfiles'       => 'array',        # Array of hashrefs
    'toc'            => 'array',        # Table of Contents, array of hashes
    'resources'      => 'hash',         # Hash of hashrefs keyed on 'type'
    'lzsslengthbits' => 'integer',
    'lzssoffsetbits' => 'integer',
    'text'           => 'string',       # Uncompressed text
    'imrn'           => 'hash',         # Hash of hashes of ImRn resource data
    'gif'            => 'hash',         # Hash of hashes of GIF image data
    'jpg'            => 'hash',         # Hash of hashes of JPEG image data
    'pic'            => 'hash',         # Hash of hashes of PICT image data
    'png'            => 'hash',         # Hash of hashes of PNG image data
    'offsetelements' => 'hash',         # Hash of text offsets to HTML elements
    );

my %rofields = (
    'unknown0x0a'   => 'string',
    'unknown0x18'   => 'integer',
    'unknown0x1c'   => 'integer',
    'unknown0x28'   => 'integer',
    'unknown0x2a'   => 'integer',
    'unknown0x2c'   => 'integer',
    );
my %privatefields = (
);

# A simple 'use fields' will not work here: use takes place inside
# BEGIN {}, so the @...fields variables won't exist.
require fields;
fields->import(
    keys(%rwfields),keys(%rofields),keys(%privatefields)
    );


=head1 CONSTRUCTOR AND INITIALIZATION

=head2 C<new($filename)>

Instantiates a new EBook::Tools::IMP object.  If C<$filename> is
specified, it will also immediately initialize itself via the C<load>
method.

=cut

sub new   ## no critic (Always unpack @_ first)
{
    my $self = shift;
    my $class = ref($self) || $self;
    my ($filename) = @_;
    my $subname = (caller(0))[3];
    debug(2,"DEBUG[",$subname,"]");

    $self = fields::new($class);
    if($filename)
    {
        $self->{filename} = $filename;
        $self->load();
    }
    return $self;
}


=head2 C<load($filename)>

Loads a .imp file, parsing it into the various object attributes.
Returns 1 on success, or undef on failure.

=cut

sub load :method
{
    my ($self,$filename) = @_;
    my $subname = (caller(0))[3];
    croak($subname . "() called as a procedure!\n") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");

    if(not $self->{filename} and not $filename)
    {
        carp($subname,"(): no filename specified!\n");
        return;
    }

    $self->{filename} = $filename if($filename);
    $filename = $self->{filename} if(!$filename);

    my $fh_imp;
    my $headerdata;
    my $bookpropdata;
    my $retval;
    my $toc_size;
    my $tocdata;
    my $entrydata;
    my $resource;       # Hashref


    if(! -f $filename)
    {
        carp($subname,"(): '",$filename,"' not found!\n");
        return;
    }

    open($fh_imp,'<:raw',$filename)
        or croak($subname,"(): unable to open '",$filename,
                 "' for reading!\n");
    sysread($fh_imp,$headerdata,48);
    $retval = $self->parse_imp_header($headerdata);
    if(!$retval)
    {
        carp($subname,"(): '",$filename,"' is not an IMP file!\n");
        return;
    }

    if(!$self->{resdiroffset})
    {
        carp($subname,"(): '",$filename,"' has no res dir offset!\n");
        return;
    }
    my $bookproplength = $self->{resdiroffset} - 24;
    sysread($fh_imp,$bookpropdata,$bookproplength);
    $retval = $self->parse_imp_book_properties($bookpropdata);

    if(!$self->{resdirlength})
    {
        carp($subname,"(): '",$filename,"' has no directory name!\n");
        return;
    }

    sysread($fh_imp,$self->{resdirname},$self->{resdirlength});

    debug(1,"DEBUG: resource directory = '",$self->{resdirname},"'");

    if($self->{version} == 1)
    {
        $toc_size = 10 * $self->{filecount};
        sysread($fh_imp,$tocdata,$toc_size)
            or croak($subname,"(): unable to read TOC data!\n");
        $self->parse_imp_toc_v1($tocdata);

        $self->{resources} = ();
        foreach my $entry (@{$self->{toc}})
        {
            sysread($fh_imp,$entrydata,$entry->{size}+10);
            $resource = parse_imp_resource_v1($entrydata);
            if($resource->{type} ne $entry->{type})
            {
                carp($subname,"():\n",
                     " '",$entry->{type},"' TOC entry pointed to '",
                     $resource->{type},"' resource!\n");
            }
            $self->{resources}->{$resource->{type}} = $resource;
        }
    }
    elsif($self->{version} == 2)
    {
        $toc_size = 20 * $self->{filecount};
        sysread($fh_imp,$tocdata,$toc_size)
            or croak($subname,"(): unable to read TOC data!\n");
        $self->parse_imp_toc_v2($tocdata);

        $self->{resources} = ();
        foreach my $entry (@{$self->{toc}})
        {
            sysread($fh_imp,$entrydata,$entry->{size}+20);
            $resource = parse_imp_resource_v2($entrydata);
            $self->{resources}->{$resource->{type}} = $resource;
        }
    }
    else
    {
        carp($subname,"(): IMP version ",$self->{version}," not supported!\n");
        return;
    }

    $self->parse_resource_images();
    $self->parse_resource_imrn();
    $self->parse_text();

    close($fh_imp)
        or croak($subname,"(): failed to close '",$filename,"'!\n");

    debug(3,$self->{text});
    return 1;
}


=head2 C<load_resdir($dirname)>

Loads a C<.RES> resource directory, parsing it into the object
attributes.  Returns 1 on success, or undef on failure.

=cut

sub load_resdir
{
    my ($self,$dirname) = @_;
    my $subname = (caller(0))[3];
    croak($subname . "() called as a procedure!\n") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");

    if(!$dirname)
    {
        carp($subname,"(): no resource directory specified!\n");
        return;
    }

    if(! -d $dirname)
    {
        carp($subname,"(): resource directory '",$dirname,"' not found!\n");
        return;
    }

    if(! -f $dirname . '/DATA.FRK')
    {
        carp($subname,"():\n",
             " resource directory '",$dirname,"' has no text resource!\n");
        return;
    }
    if(! -f $dirname . '/RSRC.INF')
    {
        carp($subname,"()\n",
             " resource directory '",$dirname,"' has no RSRC.INF!\n");
        return;
    }

    my $fh_resource;
    my $rsrcinf;
    my @list;

    open($fh_resource,'<:raw',$dirname . '/RSRC.INF')
        or croak($subname,"():\n",
                 " unable to open '$dirname/RSRC.INF' for reading!\n");
    sysread($fh_resource,$rsrcinf,-s "$dirname/RSRC.INF");
    close($fh_resource)
        or croak($subname,"():\n",
                 " unable to close '$dirname/RSRC.INF'!\n");

    if(length($rsrcinf) < 48)
    {
        carp($subname,"():\n",
             " RSRC.INF is too short (only ",length($rsrcinf)," bytes)!\n");
        return;
    }

    if(substr($rsrcinf,2,8) ne 'BOOKDOUG')
    {
        carp($subname,"():\n",
             " RSRC.INF does not contain a valid header!\n");
        return;
    }

    $self->{resdirname} = basename($dirname);
    $self->{resdirlength} = length($self->{resdirname});
    debug(2,"DEBUG: IMP resdir name = ",$self->{resdirname});

    # We have no idea what to put here, so fill it with nulls
    $self->{unknown0x0a} = "\x00\x00\x00\x00\x00\x00\x00\x00";

    # No matter what the RSRC.INF says, we're going to use a v2 format
    $self->{version} = 2;
    @list = unpack('nNNNNnCCN',substr($rsrcinf,10,26));
    $self->{resdiroffset} = $list[0];
    $self->{unknown0x18}  = $list[1];
    $self->{unknown0x1c}  = $list[2];
    $self->{compression}  = $list[3];
    $self->{encryption}   = $list[4];
    $self->{unknown0x28}  = $list[5];
    $self->{unknown0x2a}  = $list[6];
    $self->{device}       = $list[7] >> 4;
    $self->{zoomstates}   = $list[7] & 0x0f;
    $self->{unknown0x2c}  = $list[8];

    debug(2,"DEBUG: IMP resdir offset = ",$self->{resdiroffset});
    debug(2,"DEBUG: Unknown 0x18 = ",$self->{unknown0x18});
    debug(2,"DEBUG: Unknown 0x1c = ",$self->{unknown0x1c});
    debug(2,"DEBUG: IMP compression = ",$self->{compression});
    debug(2,"DEBUG: IMP encryption = ",$self->{encryption});
    debug(2,"DEBUG: Unknown 0x28 = ",$self->{unknown0x28});
    debug(2,"DEBUG: Unknown 0x2A = ",$self->{unknown0x2a});
    debug(2,"DEBUG: IMP device = ",$self->{device});
    debug(2,"DEBUG: IMP zoom state = ",$self->{zoomstates});
    debug(2,"DEBUG: Unknown 0x2c = ",$self->{unknown0x2c});

    @list = unpack('Z*Z*Z*Z*Z*Z*Z*',substr($rsrcinf,36));
    $self->{identifier}  = $list[0];
    $self->{category}    = $list[1];
    $self->{subcategory} = $list[2];
    $self->{title}       = $list[3];
    $self->{lastname}    = $list[4];
    $self->{middlename}  = $list[5];
    $self->{firstname}   = $list[6];

    my $proplength = $self->bookproplength;
    if(length($rsrcinf) > $proplength + 36)
    {
        debug(1,"Book properties data has extra ETI server data appended");
        $self->parse_eti_server_data(substr($rsrcinf,$proplength + 36));
    }

    my $cwd = getcwd();

    if(! chdir($dirname))
    {
        carp($subname,"(): unable to enter directory '",$dirname,"'!\n");
        return;
    }

    my @filelist = glob '*';
    $self->{resources} = {};
    $self->{toc} = ();
    foreach my $file (@filelist)
    {
        my $resdata;
        my %resource;
        my %tocentry;

        next if($file eq 'RSRC.INF');
        unless($file =~ /^ ([A-Z]{4} | DATA\.FRK) $/x)
        {
            debug(1,"DEBUG: invalid resource filename '",$file,
                  "' -- skipping");
            next;
        }
        if(-z $file)
        {
            debug(1,"DEBUG: resource file '",$file,
                  "' has zero size -- skipping");
            next;
        }
        open($fh_resource,'<:raw',$file)
            or croak($subname,"():\n",
                     " unable to open '",$file,"' for reading!\n");
        sysread($fh_resource,$resdata,-s $file);
        close($fh_resource)
            or croak($subname,"(): unable to close '",$file,"'!\n");
        if($file eq 'DATA.FRK')
        {
            $resource{name} = '    ';
            $resource{type} = '    ';
        }
        else
        {
            $resource{name} = $file;
            $resource{type} = detect_resource_type(\$resdata);
        }
        if(! $resource{type})
        {
            debug(1,"DEBUG: unable to determine resource type for file '",
                  $file,"' -- skipping");
            next;
        }
        $resource{unknown1} = 0;
        $resource{unknown2} = 0;
        $resource{size} = length($resdata);
        %tocentry = %resource;
        push(@{$self->{toc}},\%tocentry);

        $resource{data} = $resdata;
        $self->{resources}->{$resource{type}} = \%resource;
        debug(2,"DEBUG: found resource '",$resource{name},
              "', type '",$resource{type},"' [",$resource{size}," bytes]");
    }
    chdir($cwd);

    $self->parse_resource_images();
    $self->parse_resource_imrn();
    $self->parse_text();

    return 1;
}


######################################
########## ACCESSOR METHODS ##########
######################################


=head2 C<author()>

Returns the full name of the author of the book.

Author information can either be found entirely in the
C<< $self->{firstname} >> attribute or split up into
C<< $self->{firstname} >>, C<< $self->{middlename} >>, and
C<< $self->{lastname} >>.  If the last name is found separately,
the full name is returned in the format "Last, First Middle".
Otherwise, the full name is returned in the format "First Middle".

=cut

sub author :method
{
    my $self = shift;
    my $subname = (caller(0))[3];
    croak($subname . "() called as a procedure!\n") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");

    my $author;
    if($self->{lastname})
    {
        $author = $self->{lastname};
        if($self->{firstname})
        {
            $author .= ", " . $self->{firstname};
            $author .= " " . $self->{middlename} if($self->{middlename});
        }
    }
    else
    {
        $author = $self->{firstname};
        $author .= " " . $self->{middlename} if($self->{middlename});
    }

    return $author;
}


=head2 C<bookproplength()>

Returns the total length in bytes of the book properties data,
including the trailing null used to pack the C-style strings, but
excluding any ETI server data appended to the end of the standard book
properties.

=cut

sub bookproplength :method
{
    my $self = shift;
    my $subname = (caller(0))[3];
    croak($subname . "() called as a procedure!\n") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");

    my $length = 0;
    $length += length($self->{identifier})  + 1;
    $length += length($self->{category})    + 1;
    $length += length($self->{subcategory}) + 1;
    $length += length($self->{title})       + 1;
    $length += length($self->{lastname})    + 1;
    $length += length($self->{middlename})  + 1;
    $length += length($self->{firstname})   + 1;

    return $length;
}


=head2 C<filecount()>

Returns the number of resource files as stored in
C<< $self->{filecount} >>.  Note that this does NOT recompute that value
from the actual number of resources in C<< $self->{resources} >>.  To do
that, use L</create_toc_from_resources()>.

=cut

sub filecount :method
{
    my $self = shift;
    my $subname = (caller(0))[3];
    croak($subname . "() called as a procedure!\n") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");
    return $self->{filecount};
}


=head2 C<find_image_type($id,@excluded)>

Goes through all stored images searching for one with the specified id
value, returning the first image type found or undef if there were no
matches or if no image id was specified.  If the optional argument
C<@excluded> is specified, any types in the list will be skipped
during the search.

Expected types are 'png', 'jpg', 'gif', and 'pic', searched for in
that order.

This can be used to attempt to locate an alternate image for an
undisplayable PICT image.

=cut

sub find_image_type :method
{
    my ($self,$id,@excluded) = @_;
    my $subname = (caller(0))[3];
    croak($subname . "() called as a procedure!\n") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");

    return unless($id);

    foreach my $type (IMAGETYPES)
    {
        next if(any {$type eq $_} @excluded);
        return $type if($self->{$type}->{$id});
    }
    return;
}


=head2 C<find_resource_by_name($name)>

Takes as a single argument a resource name and if a resource with that
name exists in C<< $self->{resources} >> returns the resource type
used as the hash key.

Returns undef if no match was found or a name was not specified.

=cut

sub find_resource_by_name :method
{
    my ($self,$name) = @_;
    my $subname = (caller(0))[3];
    croak($subname . "() called as a procedure!\n") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");

    return unless($name);
    return unless($self->{resources});

    foreach my $type (keys %{$self->{resources}})
    {
        return $type if($self->{resources}->{$type}->{name} eq $name);
    }
    return;
}


=head2 C<image($type,$id)>

Returns the image data stored in the resource of the specified type
(specifically, stored in C<< $self->{$type}->{$id}->{data} >> as
parsed from the JPEG resource) corresponding to the 16-bit identifier
provided as C<$id>.

Valid values for C<$type> are 'gif','jpg', and 'png'.

Carps a warning and returns undef if C<$type> is not provided or is
not valid, or if C<$id> is not provided.

=cut

sub image :method
{
    my ($self,$type,$id) = @_;
    my $subname = (caller(0))[3];
    croak($subname . "() called as a procedure!\n") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");

    if(!$type)
    {
        carp($subname,"(): no image type specified!\n");
        return;
    }
    if(none { $type eq $_ } IMAGETYPES)
    {
        carp($subname,"(): invalid image type '",$type,"'!\n");
        return;
    }
    if(!$id)
    {
        carp($subname,"(): ID not specified!\n");
        return;
    }
    return $self->{$type}->{$id}->{data};
}


=head2 C<image_hashref($type,$id)>

Returns the raw object hashref used to store parsed image data for the
specified type, as stored in C<< $self->{$type} >>.  Valid types are
'gif', 'jpg', and 'png'.

Carps a warning and returns undef if C<$type> is not provided or is
not valid.

If C<$id> is not specified, the keys of the returned hash are the
image IDs for the specified image type, and the values are hashrefs
pointing to hashes containing the following keys:

=over

=item * C<unknown>

A 16-bit integer only available on EBW 1150 resources.  Use with
caution.  This key may be renamed if more information is found.

=item * C<length>

The length of the actual image data

=item * C<offset>

The byte offset inside of the raw resource data in which the JPEG
image data can be found.

=item * C<const0>

An unknown value, but it appears to always be zero.  Use with caution.
This key may be renamed if more information is found.

=back

If the optional argument C<$id> is specified, only the hash for that
specific ID is returned, rather than the entire hash of hashrefs.

=cut

sub image_hashref :method
{
    my ($self,$type,$id) = @_;
    my $subname = (caller(0))[3];
    croak($subname . "() called as a procedure!\n") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");

    if(!$type)
    {
        carp($subname,"(): no image type specified!\n");
        return;
    }
    if(none { $type eq $_ } IMAGETYPES)
    {
        carp($subname,"(): invalid image type '",$type,"'!\n");
        return;
    }

    if($id)
    {
        return $self->{$type}->{$id};
    }
    return $self->{$type};
}


=head2 C<image_ids($type)>

Returns a list of the 16-bit integer IDs of the the specified type of
image data stored in the associated resource (specifically, stored in
C<< $self->{$type} >> as parsed from the JPEG resource).

Valid types are 'gif', 'jpg', and 'png'.  The method will carp a
warning and return undef if another type is specified, or no type is
specified.

=cut

sub image_ids :method
{
    my ($self,$type) = @_;
    my $subname = (caller(0))[3];
    croak($subname . "() called as a procedure!\n") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");

    if(!$type)
    {
        carp($subname,"(): no image type specified!\n");
        return;
    }

    if(none { $type eq $_ } IMAGETYPES)
    {
        carp($subname,"(): invalid image type '",$type,"'!\n");
        return;
    }

    return keys %{$self->{$type}};
}


=head2 C<is_1150()>

Returns 1 if C<< $self->{device} == 2 >>, returns 0 if it is some
other value, and undef it is undefined.  This has value because
resources packed for a EBW 1150 or GEB 1150 are in a different format
than resources packed for other IMP readers.

=cut

sub is_1150
{
    my $self = shift;
    my $subname = (caller(0))[3];
    croak($subname . "() called as a procedure!\n") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");

    return if(!defined $self->{device});
    return 1 if($self->{device} == 2);
    return 0;
}


=head2 C<offsetelement($offset)>

Returns the text of the element corresponding to the given text offset
as stored in C<< $self->{offsetelements} >>, or undef if no such
element exists.

=cut

sub offsetelement :method
{
    my ($self,$offset) = @_;
    my $subname = (caller(0))[3];
    croak($subname . "() called as a procedure!\n") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");

    return unless($offset);
    return unless($self->{offsetelements});
    return $self->{offsetelements}->{$offset};
}


=head2 C<pack_imp_book_properties()>

Packs object attributes into the 7 null-terminated strings that
constitute the book properties section of the header.  Returns that
string.

Note that this does NOT pack the ETI server data appended to this
section in encrypted books downloaded directly from the ETI servers,
even if that data was found when the .imp file was loaded.  This is
because the extra data can confuse the GEBLibrarian application, and
is not needed to read the book.  The L</bookproplength()> and
L</pack_imp_header()> methods also assume that this data will not be
present.

=cut

sub pack_imp_book_properties :method
{
    my $self = shift;
    my $subname = (caller(0))[3];
    croak($subname . "() called as a procedure!\n") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");

    my $bookpropdata = pack("Z*Z*Z*Z*Z*Z*Z*",
                            $self->{identifier},
                            $self->{category},
                            $self->{subcategory},
                            $self->{title},
                            $self->{lastname},
                            $self->{middlename},
                            $self->{firstname});

    return $bookpropdata;
}


=head2 C<pack_imp_header()>

Packs object attributes into the 48-byte string representing the IMP
header.  Returns that string on success, carps a warning and returns
undef if a required attribute did not contain valid data.

Note that in the case of an encrypted e-book with ETI server data in
it, this header will not be identical to the original -- the
resdiroffset value is recalculated for the position with the ETI
server data stripped.  See L</bookproplength()> and
L</pack_imp_book_properties()>.

=cut

sub pack_imp_header :method
{
    my $self = shift;
    my $subname = (caller(0))[3];
    croak($subname . "() called as a procedure!\n") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");

    my $header;
    my $filecount = scalar(keys %{$self->{resources}});
    my $resdir = $self->{resdirname};

    if(!$filecount)
    {
        carp($subname,"():\n",
             " No resources found (has a file been loaded?)\n");
        return;
    }

    if(!$resdir)
    {
        carp($subname,"():\n",
             " No resource directory name specified!\n");
        return;
    }

    if(!$self->{version})
    {
        carp($subname,"():\n",
             " No version specified (has a file been loaded?)\n");
        return;
    }
    if($self->{version} > 2)
    {
        carp($subname,"():\n",
             " invalid version ",$self->{version},"\n");
        return;
    }

    $header = pack('n',$self->{version});
    $header .= 'BOOKDOUG';
    if(not $self->{unknown0x0a}
       or length($self->{unknown0x0a}) != 8)
    {
        carp($subname,"():\n",
             " unknown data at 0x0a has incorrect length",
             " -- substituting nulls\n");
        $self->{unknown0x0a} = "\x00\x00\x00\x00\x00\x00\x00\x00";
    }
    $header .= $self->{unknown0x0a};
    $header .= pack('nn',$filecount,length($resdir));
    $header .= pack('n',$self->bookproplength + 24);
    $header .= pack('NN',$self->{unknown0x18},$self->{unknown0x1c});
    $header .= pack('NN',$self->{compression},$self->{encryption});
    $header .= pack('nC',$self->{unknown0x28},$self->{unknown0x2a});
    $header .= pack('C',$self->{device} * 16 + $self->{zoomstates});
    $header .= pack('N',$self->{unknown0x2c});

    if(length($header) != 48)
    {
        croak($subname,"():\n",
              " total header length not 48 bytes (found ",
              length($header),")\n");
    }
    return $header;
}


=head2 C<pack_imp_resource(%args)>

Packs the specified resource stored in C<< $self->{resources} >> into
a a data string suitable for writing into a .imp file, with a header
format determined by C<< $self->{version} >>.

Returns a reference to that string if the resource was found, or undef
it was not.

=head3 Arguments

=over

=item * C<name>

Select the resource by resource name.

If both this and C<type> are specified, the type is checked first and
the name is only used if the type lookup fails.

=item * C<type>

Select the resource by resource type.  This is faster than selecting
by name (since resources are stored in a hash keyed by type) and is
recommended for most use.

If both this and C<name> are specified, the type is checked first and
the name is only used if the type lookup fails.

=back

=cut

sub pack_imp_resource :method
{
    my ($self,%args) = @_;
    my $subname = (caller(0))[3];
    croak($subname . "() called as a procedure!\n") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");

    my %valid_args = (
        'name' => 1,
        'type' => 1,
        );
    foreach my $arg (keys %args)
    {
        croak($subname,"(): invalid argument '",$arg,"'")
            if(!$valid_args{$arg});
    }
    if(not $args{name} and not $args{type})
    {
        carp($subname,"():\n",
             " at least one of name or type must be specified!\n");
        return;
    }

    my $type = $args{type};
    my $resource;
    my $resdata;

    if(not ($type and $self->{resources}->{$type}) and $args{name})
    {
        $type = $self->find_resource_by_name($args{name});
        if(not $type or not $self->{resources}->{$type})
        {
            carp($subname,"():\n",
                 " no resource with name '",$args{name},"' found!\n");
            return;
        }
    }
    if(!$self->{resources}->{$type})
    {
        carp($subname,"()\n",
             " no resource with type '",$args{type},"' found!\n");
        return;
    }

    $resource = $self->{resources}->{$type};
    if($self->{version} == 1)
    {
        $resdata = pack('a[4]nN',
                        $resource->{name},
                        $resource->{unknown1},
                        $resource->{size});
        $resdata .= $resource->{data};
    }
    elsif($self->{version} == 2)
    {
        $resdata = pack('a[4]NNa[4]N',
                        $resource->{name},
                        $resource->{unknown1},
                        $resource->{size},
                        $resource->{type},
                        $resource->{unknown2});
        $resdata .= $resource->{data};
    }
    else
    {
        carp($subname,"(): invalid version ",$self->{version},"!\n");
        return;
    }

    if(!$resdata)
    {
        carp($subname,"(): no resource data packed!\n");
        return;
    }

    return \$resdata;
}


=head2 C<pack_imp_rsrc_inf()>

Packs object attributes into the data string that would be the content
of the RSRC.INF file.  Returns that string.

=cut

sub pack_imp_rsrc_inf :method
{
    my $self = shift;
    my $subname = (caller(0))[3];
    croak($subname . "() called as a procedure!\n") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");

    my $rsrc;

    # Data from header
    $rsrc = pack('na[8]n',1,'BOOKDOUG',$self->{resdiroffset});
    $rsrc .= pack('NNNNnCCN',
                  $self->{unknown0x18},$self->{unknown0x1c},
                  $self->{compression},$self->{encryption},
                  $self->{unknown0x28},$self->{unknown0x2a},
                  ($self->{device} * 16) + $self->{zoomstates},
                  $self->{unknown0x2c});

    # Data from book properties
    $rsrc .= pack('Z*',$self->{identifier});
    $rsrc .= pack('Z*Z*Z*',
                  $self->{category},$self->{subcategory},$self->{title});
    $rsrc .= pack('Z*Z*Z*',
                  $self->{lastname},$self->{middlename},$self->{firstname});

    if($self->{etiserverdata})
    {
        my $length = length($rsrc);
        my $padsize = length($self->{etiserverdata}->{pad});

        # Pad must result in the following record being 4-byte aligned
        if( ($length + $padsize) % 4 )
        {
            carp($subname,"():\n",
                 " ETI server data has invalid pad, regenerating it...\n");
            undef($self->{etiserverdata}->{pad});
            $padsize = $length % 4;
            if($padsize)
            {
                $padsize = 4 - $padsize;
                $self->{etiserverdata}->{pad} = pack("a[$padsize]","\0");
            }
        }

        $rsrc .= $self->{etiserverdata}->{pad};
        $rsrc .= pack('NNZ*Z*',
                      $self->{etiserverdata}->{unknown1},
                      $self->{etiserverdata}->{issuenumber},
                      $self->{etiserverdata}->{contentfeed},
                      $self->{etiserverdata}->{source});
        if($self->{etiserverdata}->{unknown2})
        {
            $rsrc .= pack('N',$self->{etiserverdata}->{unknown2});
        }
    } # if($self->{etiserverdata}

    return $rsrc;
}


=head2 C<pack_imp_toc()>

Packs the C<< $self->{toc} >> object attribute into a data string
suitable for writing into a .imp file.  The format is determined by
C<< $self->{version} >>.

Returns that string, or undef if valid version or TOC data is not
found.

=cut

sub pack_imp_toc :method
{
    my $self = shift;
    my $subname = (caller(0))[3];
    croak($subname . "() called as a procedure!\n") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");

    my $tocdata;

    if(!$self->{version})
    {
        carp($subname,"():\n",
             " no version information found (did you load a file first?)\n");
        return;
    }
    if($self->{version} > 2)
    {
        carp($subname,"():\n",
             " invalid version ",$self->{version},"!\n");
        return;
    }

    if(!$self->{toc})
    {
        carp($subname,"(): no TOC data found!\n");
        return;
    }

    foreach my $entry (@{$self->{toc}})
    {
        if($self->{version} == 1)
        {
            $tocdata .= pack('a[4]nN',
                             $entry->{name},
                             $entry->{unknown1},
                             $entry->{size});
        }
        elsif($self->{version} == 2)
        {
            $tocdata .= pack('a[4]NNa[4]N',
                             $entry->{name},
                             $entry->{unknown1},
                             $entry->{size},
                             $entry->{type},
                             $entry->{unknown2});
        }
    }

    if(!length($tocdata))
    {
        carp($subname,"(): no valid TOC data produced!\n");
        return;
    }

    return $tocdata;
}


=head2 C<resdirbase()>

In scalar context, this returns the basename of C<< $self->{resdirname} >>.
In list context, it actually returns the basename, directory, and
extension as per C<fileparse> from L<File::Basename>.

=cut

sub resdirbase :method
{
    my $self = shift;
    return fileparse($self->{resdirname},'\.\w+$');
}


=head2 C<resdirlength()>

Returns the length of the .RES directory name as stored in
C<< $self->{resdirlength} >>.  Note that this does NOT recompute the
length from the actual name stored in C<< $self->{resdirname} >> --
for that, use L</set_resdirlength()>.

=cut

sub resdirlength :method
{
    my $self = shift;
    my $subname = (caller(0))[3];
    croak($subname . "() called as a procedure!\n") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");
    return $self->{resdirlength};
}


=head2 C<resdirname()>

Returns the .RES directory name stored in C<< $self->{resdirname} >>.

=cut

sub resdirname :method
{
    my $self = shift;
    my $subname = (caller(0))[3];
    croak($subname . "() called as a procedure!\n") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");
    return $self->{resdirname};
}


=head2 C<resource($type)>

Returns a hashref containing the resource data for the specified
resource type, as stored in C<< $self->{resources}->{$type} >>.

Returns undef if C<$type> is not specified, or if the specified type
is not found.

=cut

sub resource :method
{
    my ($self,$type) = @_;
    my $subname = (caller(0))[3];
    croak($subname . "() called as a procedure!\n") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");
    return unless($type);
    return $self->{resources}->{$type};
}


=head2 C<resources()>

Returns a hashref of hashrefs containing all of the resource data
keyed by type, as stored in C<< $self->{resources} >>.

=cut

sub resources :method
{
    my $self = shift;
    my $subname = (caller(0))[3];
    croak($subname . "() called as a procedure!\n") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");
    return $self->{resources};
}


=head2 C<text()>

Returns the uncompressed text originally stored in the DATA.FRK
(C<'    '>) resource.  This will only work if the text was unencrypted.

=cut

sub text :method
{
    my $self = shift;
    my $subname = (caller(0))[3];
    croak($subname . "() called as a procedure!\n") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");
    return $self->{text};
}


=head2 C<title()>

Returns the book title as stored in C<< $self->{title} >>.

=cut

sub title :method
{
    my $self = shift;
    my $subname = (caller(0))[3];
    croak($subname . "() called as a procedure!\n") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");
    return $self->{title};
}


=head2 C<tocentry($index)>

Takes as a single argument an integer index to the table of contents
data stored in C<< $self->{toc} >>.  Returns the hashref corresponding
to that TOC entry, if it exists, or undef otherwise.

=cut

sub tocentry :method
{
    my ($self,$index) = @_;
    my $subname = (caller(0))[3];
    croak($subname . "() called as a procedure!\n") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");
    return $self->{toc}->[$index];
}


=head2 C<version()>

Returns the version of the IMP format used to determine TOC and
resource metadata size as stored in C<< $self->{version} >>.  Expected
values are 1 (10-byte metadata) and 2 (20-byte metadata).

=cut

sub version :method
{
    my $self = shift;
    my $subname = (caller(0))[3];
    croak($subname . "() called as a procedure!\n") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");
    return $self->{version};
}


=head2 C<write_images(%args)>

Writes the images, if any, to the specified output directory.
Filenames are in the format C<JPEG_XXXX.jpg> or C<PNG_XXXX.png> where
C<XXXX> is the image ID for that image type formatted as four
hexadecimal characters.

=head3 Arguments

=over

=item * C<dir>

The output directory in which to write the file.  This will be created
if it does not exist.  Defaults to the basename of the stored resource
directory (see also L</resdirname()>).

=back

=cut

sub write_images :method
{
    my ($self,%args) = @_;
    my $subname = (caller(0))[3];
    croak($subname . "() called as a procedure!\n") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");

    my %valid_args = (
        'dir' => 1,
        );
    foreach my $arg (keys %args)
    {
        croak($subname,"(): invalid argument '",$arg,"'")
            if(!$valid_args{$arg});
    }

    my $dirname = $args{dir} || $self->resdirbase;
    my $cwd = usedir($dirname);

    foreach my $imagetype (IMAGETYPES)
    {
        foreach my $id (keys %{$self->{$imagetype}})
        {
            my $hexid = sprintf('%04X',$id);
            my $prefix = uc($imagetype) . '_';
            my $filename = "${prefix}${hexid}.${imagetype}";
            my $fh_image;

            if(! $self->{$imagetype}->{$id})
            {
                carp($subname,"(): data for image 0x",$hexid," not found!\n");
                next;
            }

            if(!open($fh_image,'>:raw',$filename))
            {
                carp($subname,"():\n",
                     " unable to open '",$filename,"' for writing!\n");
                return;
            }
            print {*$fh_image} $self->{$imagetype}->{$id}->{data};
            if(!close($fh_image))
            {
                carp($subname,"():\n",
                     " unable to close '",$filename,"'!\n");
                return;
            }
        } # foreach my $id (keys %{$self->{$imagetype}})
    }
    chdir($cwd);
    return 1;
}


=head2 C<write_imp($filename)>

Takes as a sole argument the name of a file to write to, and writes a
.imp file to that filename using the object attribute data.

Returns 1 on success, or undef if required data (including the
filename) was invalid or missing, or the file could not be written.

=cut

sub write_imp :method
{
    my ($self,$filename) = @_;
    my $subname = (caller(0))[3];
    croak($subname . "() called as a procedure!\n") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");

    return unless($filename);

    my $fh_imp;
    if(!open($fh_imp,'>:raw',$filename))
    {
        carp($subname,"():\n",
             " unable to open '",$filename,"' for writing!\n");
        return;
    }

    my $headerdata = $self->pack_imp_header();
    my $bookpropdata = $self->pack_imp_book_properties();
    my $tocdata = $self->pack_imp_toc;

    if(not $headerdata or length($headerdata) != 48)
    {
        carp($subname,"(): invalid header data!\n");
        return;
    }
    if(!$bookpropdata)
    {
        carp($subname,"(): invalid book properties data!\n");
        return;
    }
    if(!$tocdata)
    {
        carp($subname,"(): invalid table of contents data!\n");
        return;
    }
    if(!$self->{resdirname})
    {
        carp($subname,"(): invalid .RES directory name!\n");
        return;
    }
    if(!scalar(keys %{$self->{resources}}))
    {
        carp($subname,"(): no resources found!\n");
        return;
    }

    print {*$fh_imp} $headerdata;
    print {*$fh_imp} $bookpropdata;
    print {*$fh_imp} $self->{resdirname};
    print {*$fh_imp} $tocdata;

    foreach my $tocentry (@{$self->{toc}})
    {
        print {*$fh_imp} ${$self->pack_imp_resource(type => $tocentry->{type})};
    }

    return 1;
}


=head2 C<write_resdir()>

Writes a C<.RES> resource directory from the object attribute data,
using C<< $self->{resdirname} >> as the directory name.

=cut

sub write_resdir :method
{
    my $self = shift;
    my $subname = (caller(0))[3];
    croak($subname . "() called as a procedure!\n") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");

    if(!$self->{resdirname})
    {
        carp($subname,"(): .RES directory name not known!\n");
        return;
    }

    my $cwd = getcwd();
    my $fh_resource;

    mkpath($self->{resdirname});
    if(! -d $self->{resdirname})
    {
        croak($subname,"():\n",
              " unable to create .RES directory '",$self->{resdirname},
              "'!\n");
    }
    chdir($self->{resdirname});

    $self->{'RSRC.INF'} = $self->pack_imp_rsrc_inf;

    if($self->{'RSRC.INF'})
    {
        open($fh_resource,'>:raw','RSRC.INF')
            or croak($subname,"():\n",
                     " unable to open 'RSRC.INF' for writing!\n");

        print {*$fh_resource} $self->{'RSRC.INF'};
        close($fh_resource)
            or croak($subname,"():\n",
                     " unable to close 'RSRC.INF'!\n");
    }
    else
    {
        carp($subname,"():\n",
             " WARNING: no RSRC.INF data found!\n");
    }

    foreach my $restype (keys %{$self->{resources}})
    {
        my $filename = $self->{resources}->{$restype}->{name};
        $filename = 'DATA.FRK' if($filename eq '    ');

        open($fh_resource,'>:raw',$filename)
            or croak($subname,"():\n",
                     " unable to open '",$filename,"' for writing!\n");

        print {*$fh_resource} $self->{resources}->{$restype}->{data};
        close($fh_resource)
            or croak($subname,"():\n",
                     " unable to close '",$filename,"'!\n");
    }

    chdir($cwd);
    return 1;
}


=head2 C<write_text(%args)>

Writes the uncompressed text, if any, to the specified output
directory and file.

=head3 Arguments

=over

=item * C<dir>

The output directory in which to write the file.  This will be created
if it does not exist.  Defaults to the basename of the stored resource
directory (see also L</resdirname()>).

=item * C<filename>

The filename of the output file to write.  If not specified, a warning
will be carped and the method will return undef.

=back

=cut

sub write_text :method
{
    my ($self,%args) = @_;
    my $subname = (caller(0))[3];
    croak($subname . "() called as a procedure!\n") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");

    my %valid_args = (
        'dir' => 1,
        'filename' => 1,
        );
    foreach my $arg (keys %args)
    {
        croak($subname,"(): invalid argument '",$arg,"'")
            if(!$valid_args{$arg});
    }

    if(!$self->{text})
    {
        carp($subname,"(): no text to write!\n");
        return;
    }

    my $dirname = $args{dir} || $self->resdirbase;
    my $filename = $args{filename} || $self->resdirbase . '.html';
    $filename = $dirname . '/' . $filename;
    my $fh_text;

    mkpath($dirname) if(! -d $dirname);

    if(! -d $dirname)
    {
        carp($subname,"(): unable to create directory '",$dirname,"'!\n");
        return;
    }

    if(!open($fh_text,'>:raw',$filename))
    {
        carp($subname,"(): unable to open '",$filename,"' for writing!\n");
        return;
    }
    print {*$fh_text} $self->text;
    if(!close($fh_text))
    {
        carp($subname,"(): unable to close '",$filename,"'!\n");
        return;
    }

    return 1;
}


######################################
########## MODIFIER METHODS ##########
######################################

=head2 C<create_toc_from_resources()>

Creates appropriate table of contents data from the metadata in
C<< $self->{resources} >>, in the format specified by
C<< $self->{version} >>.  This will also set C<< $self->{filecount} >>
to match the actual number of resources.

Returns the number of resources found.

=cut

sub create_toc_from_resources :method
{
    my $self = shift;
    my $subname = (caller(0))[3];
    croak($subname . "() called as a procedure!\n") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");

    $self->{toc} = ();
    return 0 unless($self->{resources});

    foreach my $type (sort keys %{$self->{resources}})
    {
        my %tocentry;
        $tocentry{name}     = $self->{resources}->{$type}->{name};
        $tocentry{type}     = $type;
        $tocentry{size}     = length($self->{resources}->{$type}->{data});
        $tocentry{unknown1} = $self->{resources}->{$type}->{unknown1};
        $tocentry{unknown2} = $self->{resources}->{$type}->{unknown2};
        push(@{$self->{toc}},\%tocentry);
    }

    $self->{filecount} = scalar($self->{toc});
    debug(2,"DEBUG: created TOC data from ",$self->{filecount}," records");
    return $self->{filecount};
}


=head2 C<parse_eti_server_data($data)>

Parses ETI server data, as potentially found appended to the end of
.imp book properties or a RSRC.INF resource file on encrypted books
downloaded directly from ETI servers.

Takes as a single argument a string containing just the extra appended
data, and stores the parsed values in C<< $self->{etiserverdata} >> as
a hash.  Note that parsing requires knowledge of the length of the
book properties at the time this data was inserted; if the book
properties have not been properly parsed or have been modified, the
resulting behaviour of this method is not defined.

Returns the number of bytes handled, zero if no data was provided.

The data has the following format and keys:

=over

=item * [0-3 bytes]: padding data to make sure the following data is
4-byte aligned, stored in key C<pad>.

=item * [4 bytes, big-endian unsigned long int]: unknown value,
usually = 2, stored in key C<unknown1>

=item * [4 bytes, big-endian unsigned long int]: issue number for
periodicals (always 0xffffffff for books), stored in key
C<issuenumber>.

=item * [variable-length null-terminated string]: content feed for
periodicals, null string for books, stored in key C<contentfeed>.

=item * [variable-length null-terminated string]: source string in the
format C<'SOURCE_ID:SOURCE_TYPE:None'>, where C<SOURCE_ID> is usually
'3' and C<SOURCE_TYPE> is usually 'B'.

=item * [4 bytes, big-endian unsigned long int]: unknown value, stored
in key C<unknown2>.  This value may not be present at all.

=back

=cut

sub parse_eti_server_data :method
{
    my ($self,$data) = @_;
    my $subname = (caller(0))[3];
    croak($subname . "() called as a procedure!\n") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");

    return 0 unless($data);

    my $proplength = $self->bookproplength;
    my $length = length($data);
    if($length < 10)
    {
        carp($subname,"():\n",
             " data is too short to contain ETI server data! [",
             $length," bytes]\n");
        return 0;
    }

    $self->{etiserverdata} = {};

    # Up to 3 bytes of padding to make sure that the following data is
    # 4-byte aligned.
    my $padlength = $proplength % 4;
    my @list;
    if($padlength)
    {
        $padlength = 4 - $padlength;
        $self->{etiserverdata}->{pad} = substr($data,0,$padlength);
        $proplength += $padlength;
    }

    @list = unpack('NNZ*Z*N',substr($data,$padlength));
    $self->{etiserverdata}->{unknown1}    = $list[0];
    $self->{etiserverdata}->{issuenumber} = $list[1];
    $self->{etiserverdata}->{contentfeed} = $list[2];
    $self->{etiserverdata}->{source}      = $list[3];
    $self->{etiserverdata}->{unknown2}    = $list[4];
    debug(2,"  pad=",hexstring($self->{etiserverdata}->{pad}))
        if($self->{etiserverdata}->{pad});
    debug(2,
          "  unknown1=",$list[0]," \t\tissuenumber=",$list[1],"\n",
          "  contentfeed='",$list[2],"' \tsource='",$list[3],"'");
    debug(2,"  unknown2=",$list[4]) if(defined $list[4]);

    return($length);
}


=head2 C<parse_imp_book_properties($propdata)>

Takes as a single argument a string containing the book properties
data.  Sets the object variables from its contents, which should be
seven null-terminated strings in the following order:

=over

=item * Identifier

=item * Category

=item * Subcategory

=item * Title

=item * Last Name

=item * Middle Name

=item * First Name

=back

Note that the entire name is frequently placed into the "First Name"
component, and the "Last Name" and "Middle Name" components are left
blank.

In addition, ETI server data may be appended to this data on encrypted
books downloaded from ETI servers.  If present, that data will be
stored in the hash C<< $self->{etiserverdata} >>.  See
L</parse_eti_server_data($data)> for details.

A warning will be carped if the length of the parsed properties
(including the C null string terminators) is not equal to the length
of the data passed.

=cut

sub parse_imp_book_properties :method
{
    my ($self,$propdata) = @_;
    my $subname = (caller(0))[3];
    croak($subname . "() called as a procedure!\n") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");

    my @properties = unpack("Z*Z*Z*Z*Z*Z*Z*",$propdata);
    if(scalar(@properties) != 7)
    {
        carp($subname,"(): WARNING: expected 7 book properties, but found ",
             scalar(@properties),"!\n");
    }

    $self->{identifier}  = $properties[0];
    $self->{category}    = $properties[1];
    $self->{subcategory} = $properties[2];
    $self->{title}       = $properties[3];
    $self->{lastname}    = $properties[4];
    $self->{middlename}  = $properties[5];
    $self->{firstname}   = $properties[6];

    debug(2,"DEBUG: found ",scalar(@properties)," properties: ");
    debug(2,"  Identifier:   ",$self->{identifier});
    debug(2,"  Category:     ",$self->{category});
    debug(2,"  Subcategory:  ",$self->{subcategory});
    debug(2,"  Title:        ",$self->{title});
    debug(2,"  Last Name:    ",$self->{lastname});
    debug(2,"  Middle Name:  ",$self->{middlename});
    debug(2,"  First Name:   ",$self->{firstname});


    # On encrypted files, there may be addtional ETI server data
    # appended
    my $proplength = $self->bookproplength;
    if($proplength < length($propdata))
    {
        debug(1,"Book properties data has extra ETI server data appended");
        $self->parse_eti_server_data(substr($propdata,$proplength));
    }
    return 1;
}


=head2 C<parse_imp_header()>

Parses the first 48 bytes of a .IMP file, setting object variables.
The method croaks if it receives any more or less than 48 bytes.

=head3 Header Format

=over

=item * Offset 0x00 [2 bytes, big-endian unsigned short int]

Version.  Expected values are 1 or 2; the version affects the format
of the table of contents header.  If this isn't 1 or 2, the method
carps a warning and returns undef.

=item * Offset 0x02 [8 bytes]

Identifier.  This is always 'BOOKDOUG', and the method carps a warning
and returns undef if it isn't.

=item * Offset 0x0A [8 bytes]

Unknown data, stored in C<< $self->{unknown0x0a} >>.  Use with caution
-- this value may be renamed if more information is obtained.

=item * Offset 0x12 [2 bytes, big-endian unsigned short int]

Number of included files, stored in C<< $self->{filecount} >>.

=item * Offset 0x14 [2 bytes, big-endian unsigned short int]

Length in bytes of the .RES directory name, stored in
C<< $self->{resdirlength} >>.

=item * Offset 0x16 [2 bytes, big-endian unsigned short int]

Offset from the point after this value to the .RES directory name,
which also marks the end of the book properties, stored in
C<< $self->{resdiroffset} >>.  Note that this is NOT the length of the
book properties.  To get the length of the book properties, subtract
24 from this value (the number of bytes remaining in the header after
this point).  It is also NOT the offset from the beginning of the file
to the .RES directory name -- to find that, add 24 to this value (the
number of bytes already parsed).

=item * Offset 0x18 [4 bytes, big-endian unsigned long int?]

Unknown value, stored in C<< $self->{unknown0x18} >>.  Use with
caution -- this value may be renamed if more information is obtained.

=item * Offset 0x1C [4 bytes, big-endian unsigned long int?]

Unknown value, stored in C<< $self->{unknown0x1c} >>.  Use with
caution -- this value may be renamed if more information is obtained.

=item * Offset 0x20 [4 bytes, big-endian unsigned long int]

Compression type, stored in C<< $self->{compression} >>.  Expected
values are 0 (no compression) and 1 (LZSS compression).

=item * Offset 0x24 [4 bytes, big-endian unsigned long int]

Encryption type, stored in C<< $self->{encryption} >>.  Expected
values are 0 (no encryption) and 2 (DES encryption).

=item * Offset 0x28 [2 bytes, big-ending unsigned short int]

Unknown value, stored in C<< $self->{unknown0x28} >>.  Use with
caution -- this value may be renamed if more information is obtained.

=item * Offset 0x2A [1 byte]

Unknown value, stored in C<< $self->{unknown0x2A} >>.  Use with
caution -- this value may be renamed if more information is obtained.

=item * Offset 0x2B [2 nybbles (1 byte)]

The upper nybble at this position is the IMP reader device for which the
e-book was designed, stored in C<< $self->{device} >>.  Expected values
are 0 (Softbook 200/250e), 1 (REB 1200/GEB 2150), and 2 (EBW
1150/GEB1150).

The lower nybble marks the possible zoom states, stored in
C<< $self->{zoomstates} >>.  Expected values are 0 (both zooms), 1
(small zoom), and 2 (large zoom)

=item * Offset 0x2C [4 bytes, big-endian unsigned long int]

Unknown value, stored in C<< $self->{unknown0x2c} >>.  Use with
caution -- this value may be renamed if more information is obtained.

=back

=cut

sub parse_imp_header :method
{
    my ($self,$headerdata) = @_;
    my $subname = (caller(0))[3];
    croak($subname . "() called as a procedure!\n") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");

    my $length = length($headerdata);
    if($length != 48)
    {
        croak($subname,"(): expected 48 bytes, was passed ",$length,"!\n");
    }

    my $identstring = substr($headerdata,2,8);
    if($identstring ne 'BOOKDOUG')
    {
        carp($subname,"(): invalid IMP header!\n");
        return;
    }

    $self->{version} = unpack('n',$headerdata);
    if($self->{version} < 1 or $self->{version} > 2)
    {
        carp($subname,"(): Version ",$self->{version}," is not supported!\n");
        return;
    }

    $self->{unknown0x0a} = substr($headerdata,10,8);

    # Unsigned short int values
    my @list = unpack('nnn',substr($headerdata,0x12,6));
    $self->{filecount}     = $list[0];
    $self->{resdirlength}  = $list[1];
    $self->{resdiroffset}  = $list[2];
    debug(2,"DEBUG: IMP file count = ",$self->{filecount});
    debug(2,"DEBUG: IMP resdirlength = ",$self->{resdirlength});
    debug(2,"DEBUG: IMP resdir offset = ",$self->{resdiroffset});

    # Unknown long ints
    @list = unpack('NN',substr($headerdata,0x18,8));
    $self->{unknown0x18} = $list[0];
    $self->{unknown0x1c} = $list[1];
    debug(2,"DEBUG: Unknown long int at offset 0x18 = ",$self->{unknown0x18});
    debug(2,"DEBUG: Unknown long int at offset 0x1c = ",$self->{unknown0x1c});

    # Compression/Encryption/Unknown
    @list = unpack('NNnC',substr($headerdata,0x20,11));
    $self->{compression} = $list[0];
    $self->{encryption}  = $list[1];
    $self->{unknown0x28} = $list[2];
    $self->{unknown0x2a} = $list[3];
    debug(2,"DEBUG: IMP compression = ",$self->{compression});
    debug(2,"DEBUG: IMP encryption = ",$self->{encryption});
    debug(2,"DEBUG: Unknown short int at offset 0x28 = ",$self->{unknown0x28});
    debug(2,"DEBUG: Unknown byte at offset 0x2A = ",$self->{unknown0x2a});

    # Zoom State, and Unknown
    @list = unpack('CN',substr($headerdata,0x2B,5));
    $self->{device}        = $list[0] >> 4;
    $self->{zoomstates}   = $list[0] & 0x0f;
    $self->{unknown0x2c} = $list[1];

    debug(2,"DEBUG: IMP device = ",$self->{device});
    debug(2,"DEBUG: IMP zoom state = ",$self->{zoomstates});
    debug(2,"DEBUG: Unknown long int at offset 0x2c = ",$self->{unknown0x2c});

    return 1;
}


=head2 C<parse_resource_cm()>

Parses the C<!!cm> resource loaded into C<< $self->{resources} >>,
if present, extracting the LZSS uncompression parameters into
C<< $self->{lzssoffsetbits} >> and C<< $self->{lzsslengthbits} >>.

Returns 1 on success, or undef if no C<!!cm> resource has been loaded
yet or the resource data is invalid.

=cut

sub parse_resource_cm :method
{
    my $self = shift;
    my $subname = (caller(0))[3];
    croak($subname . "() called as a procedure!\n") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");

    return unless($self->{resources}->{'!!cm'});

    my @list;
    my $version;
    my $ident;          # Must be constant string '!!cm'
    my $unknown1;
    my $indexoffset;
    my $lzssdata;

    @list = unpack('na[4]NN',$self->{resources}->{'!!cm'}->{data});
    $version     = $list[0];
    $ident       = $list[1];
    $unknown1    = $list[2];
    $indexoffset = $list[3];

    if($ident ne '!!cm')
    {
        carp($subname,"():\n",
             " Invalid '!!cm' record!\n");
        return;
    }
    debug(2,"DEBUG: parsing !!cm v",$version,", index offset ",$indexoffset);
    $lzssdata = substr($self->{resources}->{'!!cm'}->{data},$indexoffset-4,4);
    @list = unpack('nn',$lzssdata);

    if($list[0] + $list[1] > 32
       or $list[0] < 2
       or $list[1] < 1)
    {
        carp($subname,"():\n",
             " invalid LZSS compression bit lengths!\n",
             "[",$list[0]," offset bits, ",
             $list[1]," length bits]\n");
        return;
    }

    $self->{lzssoffsetbits} = $list[0];
    $self->{lzsslengthbits} = $list[1];
    debug(2,"DEBUG: !!cm specifies ",$list[0]," offset bits, ",
          $list[1]," length bits");
    return 1;
}


=head2 C<parse_resource_images()>

Parses the image data resources loaded into C<< $self->{resources} >>,
if present, placing the image data and metadata of each image found
into C<< $self->{jpg} >> and C<< $self->{png} >>, keyed by 16-bit
image resource ID.

Returns the total number of images found and parsed.

This method is called automatically by L</load()> and L</load_resdir()>.

See also accessor methods L</image(%args)> and L</image_hashrefs(%args)>.

=cut

sub parse_resource_images :method
{
    my $self = shift;
    my $subname = (caller(0))[3];
    croak($subname . "() called as a procedure!\n") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");

    my $headersize;
    my $imgdata;
    my $imgcount;
    my $total = 0;
    my @list;

    if($self->{device} == DEVICE_EBW1150) { $headersize = 14; }
    else { $headersize = 12; }

    foreach my $resource (keys %IMAGE_RESOURCE_MAP)
    {
        next unless($self->{resources}->{$resource});
        my $rsize = $self->{resources}->{$resource}->{size};
        my $itype = $IMAGE_RESOURCE_MAP{$resource};
        next if ($rsize <= 32);

        @list = unpack('na[4]NNnNNNN',$self->{resources}->{$resource}->{data});
        my $version     = $list[0];
        my $ident       = $list[1];
        my $unknown1    = $list[2];
        my $tocoffset   = $list[3];
        my $unknown2    = $list[4];
        my $unknown3    = $list[5];
        my $unknown4    = $list[6];
        my $unknown5    = $list[7];
        my $unknown6    = $list[8];

        if($ident ne $resource)
        {
            carp($subname,"():\n",
                 " Invalid '",$resource,"' record!\n");
            next;
        }

        debug(2,"DEBUG: parsing ",$resource," resource v",$version,
              ", index offset ",$tocoffset);

        $imgcount = ($rsize - $tocoffset) / $headersize;

        debug(2,"DEBUG: ",$imgcount," ",$itype," images listed in header");

        $self->{$itype} = {};
        foreach my $pos (0 .. ($imgcount - 1))
        {
            my $id;         # Image ID -- this is only unique for each imagetype
            my $hexid;      # 4-digit hexadecimal string version of $id

            $imgdata = substr($self->{resources}->{$resource}->{data},
                              $tocoffset + ($headersize * $pos),$headersize);
            if($self->{device} == DEVICE_EBW1150)
            {
                #Standard 1150 Header (14 bytes)
                @list = unpack("vvVVv",$imgdata);
                $id                               = $list[0];
                $self->{$itype}->{$id}->{unknown} = $list[1];
                $self->{$itype}->{$id}->{length}  = $list[2];
                $self->{$itype}->{$id}->{offset}  = $list[3];
                $self->{$itype}->{$id}->{const0}  = $list[4];
            }
            else
            {
                #Standard 1200 Header (12 bytes)
                @list = unpack("nNNn",$imgdata);
                $id                               = $list[0];
                $self->{$itype}->{$id}->{length}  = $list[1];
                $self->{$itype}->{$id}->{offset}  = $list[2];
                $self->{$itype}->{$id}->{const0}  = $list[3];
            }

            if($EBook::Tools::debug > 2)
            {
                printf("  id=%04X  unk1=0x%04X  length=%d  offset=%d, const0=0x%04X\n",
                       $id, $self->{$itype}->{$id}->{unknown},
                       $self->{$itype}->{$id}->{length},
                       $self->{$itype}->{$id}->{offset},
                       $self->{$itype}->{$id}->{const0});
            }

            $hexid = sprintf("%04X",$id);

            $self->{$itype}->{$id}->{data} =
                substr($self->{resources}->{$resource}->{data},
                       $self->{$itype}->{$id}->{offset},
                       $self->{$itype}->{$id}->{length});

            my ($imagex,$imagey,$imagetype) =
                imgsize(\$self->{$itype}->{$id}->{data});
            if(defined($imagex) && $imagetype)
            {
                debug(2,"  ",$itype," image ",$pos," (ID '",$hexid,"') is valid ",
                      $imagetype," image data (",$imagex," x ",$imagey,")");
            }
            else
            {
                carp($subname,"():\n",
                     " ",$itype," image ",$pos," (ID '",$id,
                     "') is not valid image data!\n");
                next;
            }
        } # foreach my $pos (0 .. ($imgcount - 1))

        my $found = scalar keys %{$self->{$itype}};
        if($found != $imgcount)
        {
            carp($subname,"()\n",
                 " resource specified ",$imgcount," images, but found ",
                 $found,"!\n");
        }
        $total += $found;
    } # foreach my $resource (keys %IMAGE_RESOURCE_MAP)

    return $total;
}


=head2 C<parse_resource_imrn()>

Parses the index of text offsets to all images as stored in
C<< $self->{resources}->{'ImRn'} >>, if present, storing them in
C<< $self->{imrn} >> as a hash of hashrefs indexed by its
32-bit integer offset to the 0x0F control code in the uncompressed
text stored in the DATA.FRK resource.

Returns the total number of offsets found and parsed.

The hash keys of each offset hash are:

=over

=item * C<width>

Image display width in pixels.

=item * C<height>

Image display height in pixels.

=item * C<id>

A 16-bit integer value used to uniquely identify the image inside a
particular resource type.

=item * C<restype>

The four-letter resource type string.

=item * C<constF1>

A 32-bit value of unknown purpose which should always be 0xFFFFFFFF.

=item * C<constF2>

A second 32-bit value of unknown purpose which should always be 0xFFFFFFFF.

=item * C<const0>

A 32-bit integer value of unknown purpose which should always be 0x00000000.

=item * C<constB>

A 16-bit integer value of unknown purpose which could be 0xFFFA, 0xFFFB,
0xFFFC, or 0xFFFE.

=item * C<unknown16>

A 16-bit integer value of unknown purpose found only in 1150 resources.

=item * C<unknown32>

A 32-bit integer value of unknown purpose.

=back

This method is called automatically by L</load()> and L</load_resdir()>.

=cut

sub parse_resource_imrn :method
{
    my $self = shift;
    my $subname = (caller(0))[3];
    croak($subname . "() called as a procedure!\n") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");

    return unless($self->{resources}->{'ImRn'});

    my $headersize;
    my $imrndata;
    my $imrncount;
    my $total = 0;
    my @list;
    my $idxdata;
    my $idxsize;
    my $idx1id;
    my $idx1size;
    my $idx1offset;
    my $idx1const0;

    if($self->{device} == DEVICE_EBW1150)
    {
         $headersize = 36;
         $idxsize = 14;
    }
    else
    {
         $headersize = 32;
         $idxsize = 12;
    }

    my $rsize = $self->{resources}->{'ImRn'}->{size};
    next if ($rsize <= 32);

    @list = unpack('na[4]NNnNNNN',$self->{resources}->{'ImRn'}->{data});
    my $version     = $list[0];
    my $ident       = $list[1];
    my $unknown1    = $list[2];
    my $tocoffset   = $list[3];
    my $unknown2    = $list[4];
    my $unknown3    = $list[5];
    my $unknown4    = $list[6];
    my $unknown5    = $list[7];
    my $unknown6    = $list[8];

    if($ident ne 'ImRn')
    {
        carp($subname,"():\n",
             " Invalid 'ImRn' record!\n");
        next;
    }

    debug(2,"DEBUG: parsing 'ImRn' resource v",$version,
          ", index offset ",$tocoffset);

    $imrncount = ($rsize - 32 - 12) / $headersize;

    debug(2,"DEBUG: ",$imrncount," images listed in header");

    $self->{imrn} = {};
    foreach my $pos (0 .. ($imrncount - 1))
    {
        my $offset;     # offset within DATA.FRK text (0x0F) of image insertion

        # FIX: The last (number $imrncount) image record is 2 bytes shorter and
        # will not be of size 36, but 34.  Currently this code will read into
        # the index record!
        $imrndata = substr($self->{resources}->{'ImRn'}->{data},
                           32 + ($headersize * $pos),$headersize);
        if($self->{device} == DEVICE_EBW1150)
        {
            #imrn 1150 record
            @list = unpack("VVvvVvvVVa[4]v",$imrndata);
            $offset                               = $list[7];

            $self->{imrn}->{$offset}->{constF1}   = $list[0];
            $self->{imrn}->{$offset}->{constF2}   = $list[1];
            $self->{imrn}->{$offset}->{width}     = $list[2];
            $self->{imrn}->{$offset}->{height}    = $list[3];
            $self->{imrn}->{$offset}->{const0}    = $list[4];
            $self->{imrn}->{$offset}->{unknown16} = $list[5];
            $self->{imrn}->{$offset}->{constB}    = $list[6];
            $self->{imrn}->{$offset}->{unknown32} = $list[8];
            $self->{imrn}->{$offset}->{restype}   = $list[9];
            $self->{imrn}->{$offset}->{id}        = $list[10];

            # restypes only reversed in 1150 ebooks
            # (restypes in 1200 ebooks are not reversed)
            my %restypefix = (
                ' FIG' => 'GIF ',
                'GEPJ' => 'JPEG',
                ' GNP' => 'PNG ',
                '2CIP' => 'PIC2',
                'TCIP' => 'PICT',
                );
            my $type = $self->{imrn}->{$offset}->{restype};
            $self->{imrn}->{$offset}->{restype} = $restypefix{$type}
                if($restypefix{$type});
        }
        else
        {
            #imrn 1200 record
            @list = unpack("NNnnNnNNa[4]n",$imrndata);
            $offset                               = $list[6];

            $self->{imrn}->{$offset}->{constF1}   = $list[0];
            $self->{imrn}->{$offset}->{constF2}   = $list[1];
            $self->{imrn}->{$offset}->{width}     = $list[2];
            $self->{imrn}->{$offset}->{height}    = $list[3];
            $self->{imrn}->{$offset}->{const0}    = $list[4];
            $self->{imrn}->{$offset}->{constB}    = $list[5];
            $self->{imrn}->{$offset}->{unknown32} = $list[7];
            $self->{imrn}->{$offset}->{restype}   = $list[8];
            $self->{imrn}->{$offset}->{id}        = $list[9];
        }

        my $restype = $self->{imrn}->{$offset}->{restype};
        my $imgtype = $IMAGE_RESOURCE_MAP{$restype};
        my $hexid = sprintf('%04X',$self->{imrn}->{$offset}->{id});
        my $width = $self->{imrn}->{$offset}->{width};
        my $height = $self->{imrn}->{$offset}->{height};

        if(none { $restype eq $_ } (IMAGERESOURCES) )
        {
            carp($subname,"():\n",
                 " invalid image type '",$restype,"' at offset ",$offset,"!\n");
            next;
        }
        debug(2,"DEBUG: ImRn offset ",$offset,": '",$restype,"' 0x",$hexid,
              " (",$width," x ",$height,")");

        # PICT images are unviewable, so see if there is an alternate to use instead
        if($imgtype and $imgtype eq 'pic')
        {
            my $id = $self->{imrn}->{$offset}->{id};
            my $alttype = $self->find_image_type($id,'pic');
            $imgtype = $alttype if($alttype);
        }

        #TODO: use height/width from Pcz0/PcZ0 records
        my $filename = uc($imgtype) . "_${hexid}.${imgtype}";
        $self->{offsetelements}->{$offset} =
            '<img src="' . $filename . '" width="' . $width . '" height="' . $height
            . '" alt="' . $filename . '" />';

        debug(2,"DEBUG: tag = '",$self->{offsetelements}->{$offset},"'");
        if($EBook::Tools::debug > 2)
        {
            printf("  offset=%d restype=%s imgid=%04X constF1=0x%04X constF2=0x%04X width=%d  height=%d  const0=0x%04X, constB=0x%04X",
                   $offset, $self->{imrn}->{$offset}->{restype},
                   $self->{imrn}->{$offset}->{id},
                   $self->{imrn}->{$offset}->{constF1},
                   $self->{imrn}->{$offset}->{constF2},
                   $self->{imrn}->{$offset}->{width},
                   $self->{imrn}->{$offset}->{height},
                   $self->{imrn}->{$offset}->{const0},
                   $self->{imrn}->{$offset}->{constB},
                   $self->{imrn}->{$offset}->{unknown16},
                   $self->{imrn}->{$offset}->{unknown32});

            if($self->{imrn}->{$offset}->{const2})
            {
                printf(" const2=0x%04X",
                       $self->{imrn}->{$offset}->{const2});
            }
            printf("\n");
        }
    }

    $idxdata = substr($self->{resources}->{'ImRn'}->{data},$tocoffset,$idxsize);
    if($self->{device} == DEVICE_EBW1150)
    {
        #Standard 1150 (14-byte) Index Header
        @list = unpack("vVVV",$idxdata);
    }
    else
    {
        #Standard 1200 (12-byte) Index Header
        @list = unpack("nNNn",$idxdata);
    }
    $idx1id     = $list[0];
    $idx1size   = $list[1];
    $idx1offset = $list[2];
    $idx1const0 = $list[3];

    $total = scalar keys %{$self->{imrn}};
    if($total != $imrncount)
    {
        carp($subname,"()\n",
             " resource specified ",$imrncount," ImRn entries, but found ",
             $total,"!\n");
    }

    return $total;
}


=head2 C<parse_text()>

Parses the C<'    '> (DATA.FRK) resource loaded into
C<< $self->{resources} >>, if present, extracting the text into
C<< $self->{text} >>, uncompressing it if necessary.  LZSS uncompression
will use the C<< $self->{lzsslengthbits} >> and
C<< $self->{lzssoffsetbits} >> attributes if present, and default to 3
length bits and 14 offset bits otherwise.

HTML headers and footers are then applied, and control codes replaced
with appropriate tags.

Returns the length of the raw uncompressed text before any HTML
modification was done, or undef if no text resource was found or the
text was encrypted.

=cut

sub parse_text :method
{
    my $self = shift;
    my $subname = (caller(0))[3];
    croak($subname . "() called as a procedure!\n") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");

    return unless($self->{resources}->{'    '});

    $self->parse_resource_cm();
    my $lengthbits = $self->{lzsslengthbits} || 3;
    my $offsetbits = $self->{lzssoffsetbits} || 14;
    my $lzss = EBook::Tools::LZSS->new(lengthbits => $lengthbits,
                                       offsetbits => $offsetbits,
                                       windowstart => 1);
    my $textref;
    my $textlength;

    if($self->{encryption})
    {
        warn($subname,"(): encrypted text not supported!\n");
        return;
    }

    if($self->{compression})
    {
        $textref = $lzss->uncompress(\$self->{resources}->{'    '}->{data});
    }
    else
    {
        $textref = \$self->{resources}->{'    '}->{data};
    }
    $textlength = length($$textref);

    if(!$textlength)
    {
        carp($subname,"(): no text extracted from DATA.FRK resource!\n");
        return;
    }

    $self->{text} = <<'END';
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <meta http-equiv="CONTENT-TYPE" content="text/html; charset=windows-1252" />
END

    $self->{text} .= "  <title>$self->{title}</title>\n";
    $self->{text} .= "</head>\n<body>\n";

    my $pos = 0;
    my %ccharmap = (
        0x0A => "\n" . '<br style="page-break-before: always" />', # supported!
        0x0B => "\n<p>",
        0x0D => "<br />\n",
        0x0E => '',             # Start of <table>, not yet supported
        0x13 => '',             # End of table cell </td>, not yet supported
        0x14 => "\n<hr />\n",
        0x8E => "&eacute;",
        0xA0 => "&nbsp;",
        0xA5 => "&bull;",
        0xA8 => "&reg;",
        0xA9 => "&copy;",
        0xAA => "&trade;",
        0xAE => "&AElig;",
        0xC7 => "&laquo;",
        0xC8 => "&raquo;",
        0xC9 => "&hellip;",
        0xD0 => "&ndash;",
        0xD1 => "&mdash;",
        0xD2 => "&ldquo;",
        0xD3 => "&rdquo;",
        0xD4 => "&lsquo;",
        0xD5 => "&rsquo;",
        0xE1 => "&middot;",
        );

    while($pos < $textlength)
    {
        my $char = substr($$textref,$pos,1);
        my $ord = ord($char);

        if($ord == 0x0F)        # Image
        {
            $self->{text} .= $self->{offsetelements}->{$pos};
        }
        elsif(defined $ccharmap{$ord})
        {
            $self->{text} .= $ccharmap{$ord};
        }
        else
        {
            $self->{text} .= $char;
        }
        $pos++;
    }
    $self->{text} .= "\n</body>\n</html>";
    $self->{text} =~ s/\x15 .*? \x15//gx;        # Kill header - comment out?
    $self->{text} =~ s/\x16 .*? \x16//gx;        # Kill footer
    return $textlength;
}


=head2 C<parse_imp_toc_v1($tocdata)>

Takes as a single argument a string containing the table of contents
data, and parses it into object attributes following the version 1
format (10 bytes per entry).

=head3 Format

=over

=item * Offset 0x00 [4 bytes, text]

Resource name.  Stored in hash key C<name>.  In the case of the
'DATA.FRK' text resource, this will be four spaces (C<'    '>).

=item * Offset 0x04 [2 bytes, big-endian unsigned short int]

Unknown, but always zero or one.  Stored in hash key C<unknown1>.

=item * Offset 0x08 [4 bytes, big-endian unsigned long int]

Size of the resource data in bytes.  Stored in hash key C<size>.

=back

=cut

sub parse_imp_toc_v1 :method
{
    my ($self,$tocdata) = @_;
    my $subname = (caller(0))[3];
    croak($subname . "() called as a procedure!\n") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");

    my $length = length($tocdata);
    my $lengthexpected = 10 * $self->{filecount};
    my $tocentrydata;
    my $offset = 0;

    if($self->{version} != 1)
    {
        carp($subname,"(): attempting to parse a version 1 TOC,",
             " but the file appears to be version ",$self->{version},"!\n");
    }

    if($length != $lengthexpected)
    {
        carp($subname,"(): expected ",$lengthexpected," bytes, but received ",
             $length," -- aborting!\n");
        return;
    }

    $self->{toc} = ();
    foreach my $index (0 .. $self->{filecount} - 1)
    {
        my %tocentry;
        my @list;
        $tocentrydata = substr($tocdata,$offset,10);
        @list = unpack('a[4]nN',$tocentrydata);

        $tocentry{name}     = $list[0];
        $tocentry{unknown1} = $list[1];
        $tocentry{size}     = $list[2];

        debug(3,"DEBUG: found toc entry '",$tocentry{name},
              "', type '",$tocentry{type},"' [",$tocentry{size}," bytes]");
        push(@{$self->{toc}}, \%tocentry);
        $offset += 10;
    }

    return 1;
}


=head2 C<parse_imp_toc_v2($tocdata)>

Takes as a single argument a string containing the table of contents
data, and parses it into object attributes following the version 2
format (20 bytes per entry).

=head3 Format

=over

=item * Offset 0x00 [4 bytes, text]

Resource name.  Stored in C<name>.  In the case of the 'DATA.FRK' text
resource, this will be four spaces (C<'   '>).

=item * Offset 0x04 [4 bytes, big-endian unsigned long int]

Unknown, but always zero.  Stored in C<unknown1>.

=item * Offset 0x08 [4 bytes, big-endian unsigned long int]

Size of the resource data in bytes.  Stored in C<size>.

=item * Offset 0x0C [4 bytes, text]

Resource type.  Stored in C<type>, and used as the key for the stored
resource hash.

=item * Offset 0x10 [4 bytes, big-endian unsigned long int]

Unknown, but always either zero or one.  Stored in C<unknown2>.

=back

=cut

sub parse_imp_toc_v2 :method
{
    my ($self,$tocdata) = @_;
    my $subname = (caller(0))[3];
    croak($subname . "() called as a procedure!\n") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");

    my $length = length($tocdata);
    my $lengthexpected = 20 * $self->{filecount};
    my $template;
    my $tocentrydata;
    my $offset = 0;

    if($self->{version} != 2)
    {
        carp($subname,"(): attempting to parse a version 2 TOC,",
             " but the file appears to be version ",$self->{version},"!\n");
    }

    if($length != $lengthexpected)
    {
        carp($subname,"(): expected ",$lengthexpected," bytes, but received ",
             $length," -- aborting!\n");
        return;
    }

    $self->{toc} = ();
    foreach my $index (0 .. $self->{filecount} - 1)
    {
        my %tocentry;
        my @list;
        $tocentrydata = substr($tocdata,$offset,20);
        @list = unpack('a[4]NNa[4]N',$tocentrydata);

        $tocentry{name}     = $list[0];
        $tocentry{unknown1} = $list[1];
        $tocentry{size}     = $list[2];
        $tocentry{type}     = $list[3];
        $tocentry{unknown2} = $list[4];

        debug(3,"DEBUG: found toc entry '",$tocentry{name},
              "', type '",$tocentry{type},"' [",$tocentry{size}," bytes,",
              " unk1=",$tocentry{unknown1}," unk2=",$tocentry{unknown2},"]");
        push(@{$self->{toc}}, \%tocentry);
        $offset += 20;
    }

    return 1;
}


=head2 C<set_book_properties(%args)>

Sets the specified book properties.  Returns 1 on success, or undef if
no properties were specified.

=head3 Arguments

=over

=item * C<identifier>

The book identifier, as might be provided as an OPF C<< <dc:identifier> >>
element.

=item * C<category>

The main book category, as might be provided as an OPF C<< <dc:subject> >>
element.

=item * C<subcategory>

The subcategory, generally a set of search arguments for the ETI
website.

=item * C<title>

The book title, as might be provided as an OPF C<< <dc:title> >>
element.

=item * C<lastname>

The primary author's last name, but see the entry for C<firstname>
before deciding how to handle name storage.

=item * C<middlename>

The primary author's middle name, but see the entry for C<firstname>
before deciding how to handle name storage.

=item * C<firstname>

The primary author's first name, but this field is also used by a
great many .imp books to store the entire name in "First Last" format.
If this field is to be used this way, C<lastname> and C<middlename>
must be blank.

=back

=head3 Example

 $imp->set_book_properties(title => 'My Best Book',
                           category => 'Fiction',
                           firstname => 'John Q. Public');

=cut

sub set_book_properties :method
{
    my ($self,%args) = @_;
    my $subname = (caller(0))[3];
    croak($subname . "() called as a procedure!\n") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");

    my %valid_args = (
        'identifier'  => 1,
        'category'    => 1,
        'subcategory' => 1,
        'title'       => 1,
        'lastname'    => 1,
        'middlename'  => 1,
        'firstname'   => 1,
        );
    if(!%args)
    {
        carp($subname,"():\n",
             " at least one property must be specified!\n");
        return;
    }
    foreach my $arg (keys %args)
    {
        croak($subname,"(): invalid argument '",$arg,"'")
            if(!$valid_args{$arg});
    }

    $self->{identifier}  = $args{identifier} if(defined $args{identifier});
    $self->{category}    = $args{category} if(defined $args{category});
    $self->{subcategory} = $args{subcategory} if(defined $args{subcategory});
    $self->{title}       = $args{title} if(defined $args{title});
    $self->{lastname}    = $args{lastname} if(defined $args{lastname});
    $self->{middlename}  = $args{middlename} if(defined $args{middlename});
    $self->{firstname}   = $args{firstname} if(defined $args{firstname});

    return 1;
}


################################
########## PROCEDURES ##########
################################

=head1 PROCEDURES

All procedures are exportable, but none are exported by default.


=head2 C<detect_resource_type(\$data)>

Takes as a sole argument a reference to the data component of a
resource.  Returns a 4-byte string containing the resource type if
detected successfully, or undef otherwise.

Detection will not work on the C<DATA.FRK> (C<'   '>) resource.  That
one must be detected separately by name/type.

=cut

sub detect_resource_type
{
    my ($dataref) = @_;
    my $subname = (caller(0))[3];
    debug(3,"DEBUG[",$subname,"]");

    if(!$dataref)
    {
        carp($subname,"(): no resource data provided!\n");
        return;
    }
    if(ref $dataref ne 'SCALAR')
    {
        carp($subname,"(): argument is not a scalar reference!\n");
        return;
    }

    my $id = substr($$dataref,2,4);
    if($id =~ m/^[\w! ]{4}$/)
    {
        return $id;
    }
    carp($subname,"(): resource not recognized!\n");
    return;
}


=head2 C<parse_imp_resource_v1()>

Takes as a sole argument a string containing the data (including the
10-byte header) of a version 1 IMP resource.

Returns a hashref containing that data separated into the following
keys:

=over

=item * C<name>

The four-letter name of the resource.

=item * C<type>

The four-letter type of the resource.  This is detected from the data,
and is not part of the v1 header.

=item * C<unknown1>

A 16-bit unsigned int of unknown purpose.  Expected values are 0 or 1.

Use with caution.  This key may be renamed later if more information
is found.

=item * C<size>

The expected size in bytes of the actual resource data.  A warning
will be carped if this does not match the actual size of the data
following the header.

=item * C<data>

The actual resource data.

=back

=cut

sub parse_imp_resource_v1
{
    my ($data) = @_;
    my $subname = (caller(0))[3];
    debug(3,"DEBUG[",$subname,"]");

    my @list;           # Temporary list
    my %resource;       # Hash containing resource data and metadata
    my $size;           # Actual size of resource data

    @list = unpack('a[4]nN',$data);
    $resource{name}     = $list[0];
    $resource{unknown1} = $list[1];
    $resource{size}     = $list[2];
    $resource{data}     = substr($data,10);
    if($resource{name} eq '    ')
    {
        $resource{type} = '    ';
    }
    else
    {
        $resource{type} = detect_resource_type(\$resource{data});
    }

    $size = length($resource{data});
    if($size != $resource{size})
    {
        carp($subname,"(): resource '",$resource{name},"' has ",
             $size," bytes (expected ",$resource{size},")!\n");
    }

    debug(2,"DEBUG: found resource '",$resource{name},
          "', type '",$resource{type},"' [",$resource{size}," bytes]");

    return \%resource;
}


=head2 C<parse_imp_resource_v2()>

Takes as a sole argument a string containing the data (including the
20-byte header) of a version 2 IMP resource.

Returns a hashref containing that data separated into the following
keys:

=over

=item * C<name>

The four-letter name of the resource.

=item * C<unknown1>

A 32-bit unsigned int of unknown purpose.  Expected values are 0 or 1.

Use with caution.  This key may be renamed later if more information
is found.

=item * C<size>

The expected size in bytes of the actual resource data.  A warning
will be carped if this does not match the actual size of the data
following the header.

=item * C<type>

The four-letter type of the resource.

=item * C<unknown2>

A 32-bit unsigned int of unknown purpose.  Expected values are 0 or 1.

Use with caution.  This key may be renamed later if more information
is found.

=item * C<data>

The actual resource data.

=back

=cut

sub parse_imp_resource_v2
{
    my ($data) = @_;
    my $subname = (caller(0))[3];
    debug(3,"DEBUG[",$subname,"]");

    my @list;           # Temporary list
    my %resource;       # Hash containing resource data and metadata
    my $size;           # Actual size of resource data

    @list = unpack('a[4]NNa[4]N',$data);
    $resource{name}     = $list[0];
    $resource{unknown1} = $list[1];
    $resource{size}     = $list[2];
    $resource{type}     = $list[3];
    $resource{unknown2} = $list[4];
    $resource{data}     = substr($data,20);

    $size = length($resource{data});
    if($size != $resource{size})
    {
        carp($subname,"(): resource '",$resource{name},"' has ",
             $size," bytes (expected ",$resource{size},")!\n");
    }

    debug(2,"DEBUG: found resource '",$resource{name},
          "', type '",$resource{type},"' [",$resource{size}," bytes,",
          " unk1=",$resource{unknown1}," unk2=",$resource{unknown2},"]");

    return \%resource;
}


########## END CODE ##########

=head1 BUGS AND LIMITATIONS

=over

=item * Not finished.  Do not try to use yet.

=item * MacPaint PICT images are not well-supported.  If present in
the book, they will be saved, but a warning will be carped about
invalid image data.

=item * Support for v1 files is completely untested and implemented
with some guesswork.  Bug reports welcome.

=back

=head1 AUTHOR

Zed Pobre <zed@debian.org>

=head1 THANKS

Thanks are due to Nick Rapallo <nrapallo@yahoo.ca> for invaluable
assistance in understanding the .IMP format and testing this code.

Thanks are also due to Jeffrey Kraus-yao <krausyaoj@ameritech.net> for
his work reverse-engineering the .IMP format to begin with, and the
documentation at L<http://krausyaoj.tripod.com/reb1200.htm>.

=head1 LICENSE AND COPYRIGHT

Copyright 2008 Zed Pobre

Licensed to the public under the terms of the GNU GPL, version 2.

=cut

1;
__END__

