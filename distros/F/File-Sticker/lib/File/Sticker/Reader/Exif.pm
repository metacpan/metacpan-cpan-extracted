package File::Sticker::Reader::Exif;
$File::Sticker::Reader::Exif::VERSION = '3.0008';
=head1 NAME

File::Sticker::Reader::Exif - read and standardize meta-data from EXIF file

=head1 VERSION

version 3.0008

=head1 SYNOPSIS

    use File::Sticker::Reader::Exif;

    my $obj = File::Sticker::Reader::Exif->new(%args);

    my %meta = $obj->read_meta($filename);

=head1 DESCRIPTION

This will read meta-data from EXIF files, and standardize it to a common
nomenclature, such as "tags" for things called tags, or Keywords or Subject etc.

=cut

use v5.10;
use common::sense;
use Carp;
use File::LibMagic;
use Image::ExifTool qw(:Public);
use YAML::Any;
use File::Spec;

use parent qw(File::Sticker::Reader);

# FOR DEBUGGING
=head1 DEBUGGING

=head2 whoami

Used for debugging info

=cut
sub whoami  { ( caller(1) )[3] }

=head1 METHODS

=head2 priority

The priority of this reader.  Readers with higher priority get tried first.

=cut

sub priority {
    my $class = shift;
    return 1;
} # priority

=head2 allowed_file

If this reader can be used for the given file, then this returns true.
File must be one of: PDF or an image which is not a GIF.
(GIF files need to be treated separately)
(Since ExifTool can't write to EPUB, there's no point reading them either.)

=cut

sub allowed_file {
    my $self = shift;
    my $file = shift;
    say STDERR whoami(), " filename=$file" if $self->{verbose} > 2;

    $file = $self->_get_the_real_file(filename=>$file);
    my $ft = $self->{file_magic}->info_from_filename($file);
    if ($ft->{mime_type} =~ /(image|pdf)/
            and $ft->{mime_type} !~ /gif/)
    {
        return 1;
    }
    return 0;
} # allowed_file

=head2 known_fields

Returns the fields which this reader knows about.

    my $known_fields = $reader->known_fields();

=cut

sub known_fields {
    my $self = shift;

    return {
        title=>'TEXT',
        creator=>'TEXT',
        description=>'TEXT',
        location=>'TEXT',
        tags=>'MULTI',
        date=>'TEXT',
        copyright=>'TEXT',
        flash=>'TEXT',
        imagesize=>'TEXT',
        imageheight=>'NUMBER',
        imagewidth=>'NUMBER',
        megapixels=>'NUMBER',
        %{$self->{wanted_fields}},
    };
} # known_fields

=head2 read_meta

Read the meta-data from the given file.

    my $meta = $obj->read_meta($filename);

=cut

sub read_meta {
    my $self = shift;
    my $filename = shift;
    say STDERR whoami(), " filename=$filename" if $self->{verbose} > 2;

    $filename = $self->_get_the_real_file(filename=>$filename);
    my $info = ImageInfo($filename);
    my %meta = ();

    # Check if this is a Gutenberg book; they have quirks.
    my $is_gutenberg_book = 0;
    if (exists $info->{Identifier}
            and $info->{'Identifier'} =~ m!http://www.gutenberg.org/ebooks/\d+!)
    {
        $is_gutenberg_book = 1;
        # If this is a Gutenberg book, the Identifier holds the correct URL
        $meta{'url'} = $info->{'Identifier'};
    }
    # There are multiple fields which could be used as a file "description".
    # Check through them until you find a non-empty one.
    my $description = '';
    foreach my $field (qw(Caption-Abstract Comment UserComment ImageDescription Description))
    {
        if (exists $info->{$field}
                and $info->{$field}
                and $info->{$field} !~ /^---/ # YAML - not a description!
                and !$description)
        {
            $description = $info->{$field};
            $description =~ s/\n$//; # remove trailing newlines
        }
    }
    $meta{description} = $description if $description;
    # There are multiple fields which could be used as a file content creator.
    # Check through them until you find a non-empty one.
    my $creator = '';
    foreach my $field (qw(Author Artist Creator))
    {
        if (exists $info->{$field} and $info->{$field} and !$creator)
        {
            $creator = $info->{$field};
        }
    }
    $meta{creator} = $creator if $creator;

    # There are multiple fields which could be used as a copyright notice.
    # Check through them until you find a non-empty one.
    my $copyright = '';
    foreach my $field (qw(License Rights))
    {
        if (exists $info->{$field} and $info->{$field} and !$copyright)
        {
            $copyright = $info->{$field};
        }
    }
    $meta{copyright} = $copyright if $copyright;

    # There are multiple fields which could be used as a file date.
    # Check through them until you find a non-empty one.
    my $date = '';
    foreach my $field (qw(CreateDate DateTimeOriginal Date PublishedDate PublicationDate))
    {
        if (exists $info->{$field} and $info->{$field} and !$date)
        {
            $date = $info->{$field};
        }
    }
    $meta{date} = $date if $date;

    # Use a consistent naming for tag fields.
    # Combine the tag-like fields together.
    # Put them in a hash because there might be duplicates
    my %tags = ();
    foreach my $field (qw(Keywords Subject))
    {
        if (exists $info->{$field} and $info->{$field})
        {
            my $val = $info->{$field};
            my @tags;
            if ($is_gutenberg_book)
            {
                # gutenberg tags are multi-word, separated by comma-space or ' -- '
                # and can have parens in them
                $val =~ s/\(//g;
                $val =~ s/\)//g;
                $val =~ s/\s--\s/,/g;
                @tags = split(/,\s?/, $val);
            }
            else
            {
                @tags = split(/,\s*/, $val);
            }
            foreach my $t (@tags)
            {
                $t =~ s/ - / /g; # remove isolated dashes
                $t =~ s/[^\w\s,-]//g; # remove non-word characters
                $tags{$t}++;
            }
        }
    }
    # Make the tags an array, not a string
    if (keys %tags)
    {
        $meta{tags} = [sort keys %tags];
    }
    else # remove empty tag-field
    {
        delete $meta{tags};
    }

    # There are SOOOOOO many fields in EXIF data, just remember a subset of them
    foreach my $field (qw(
Flash
ImageHeight
ImageSize
ImageWidth
Megapixels
PageCount
Location
Title
))
    {
        if (exists $info->{$field} and $info->{$field})
        {
            $meta{lc($field)} = $info->{$field};
        }
    }

    # -------------------------------------------------
    # Freeform Fields
    # These are stored as YAML data in the XMP:Description field.
    # They used to be stored in the ImageDescription field then
    # the UserComment field, so they need to be checked too.
    # -------------------------------------------------
    if (exists $info->{Description}
            and $info->{Description}
            and $info->{Description} =~ /^---/)
    {
        say STDERR sprintf("Description='%s'", $info->{Description}) if $self->{verbose} > 2;
        my $data;
        eval {$data = Load($info->{Description});};
        if ($@)
        {
            warn __PACKAGE__, " Load of YAML data failed: $@";
        }
        elsif (!$data)
        {
            warn __PACKAGE__, " no legal YAML" if $self->{verbose} > 2;
        }
        else # okay
        {
            foreach my $field (sort keys %{$data})
            {
                $meta{$field} = $data->{$field};
            }
        }
    }
    elsif (exists $info->{ImageDescription}
            and $info->{ImageDescription}
            and $info->{ImageDescription} =~ /^---/)
    {
        say STDERR sprintf("ImageDescription='%s'", $info->{ImageDescription}) if $self->{verbose} > 2;
        my $data;
        eval {$data = Load($info->{ImageDescription});};
        if ($@)
        {
            warn __PACKAGE__, " Load of YAML data failed: $@";
        }
        elsif (!$data)
        {
            warn __PACKAGE__, " no legal YAML" if $self->{verbose} > 2;
        }
        else # okay
        {
            foreach my $field (sort keys %{$data})
            {
                $meta{$field} = $data->{$field};
            }
        }
    }
    elsif (exists $info->{UserComment}
            and $info->{UserComment}
            and $info->{UserComment} =~ /^---/)
    {
        say STDERR sprintf("UserComment='%s'", $info->{UserComment}) if $self->{verbose} > 2;
        my $data;
        eval {$data = Load($info->{UserComment});};
        if ($@)
        {
            warn __PACKAGE__, " Load of YAML data failed: $@";
        }
        elsif (!$data)
        {
            warn __PACKAGE__, " no legal YAML" if $self->{verbose} > 2;
        }
        else # okay
        {
            foreach my $field (sort keys %{$data})
            {
                $meta{$field} = $data->{$field};
            }
        }
    }

    return \%meta;
} # read_meta

=head2 _get_the_real_file

If the file is a directory, look for a cover file.
If the file is a soft link, look for the file it is pointing to
(because ExifTool behaves badly with soft links).

    my $real_file = $writer->_get_the_real_file(filename=>$filename);

=cut

sub _get_the_real_file {
    my $self = shift;
    my %args = @_;
    say STDERR whoami(), " filename=$args{filename}" if $self->{verbose} > 2;

    my $filename = $args{filename};
    if (-d $filename) # is a directory, look for a cover file
    {
        my $cover_file = ($self->{cover_file} ? $self->{cover_file} : 'cover.jpg');
        $cover_file = File::Spec->catfile($filename, $cover_file);
        if (-f $cover_file)
        {
            $filename = $cover_file;
        }
        else # give up and die
        {
            croak "$args{filename} is directory, cannot find $cover_file";
        }
    }
    # ExifTool has a wicked habit of replacing soft-linked files with the
    # contents of the file rather than honouring the link.  While using the
    # exiftool script offers -overwrite_original_in_place to deal with this,
    # the Perl module does not appear to have such an option available.

    # So the way to get around this is to check if the file is a soft link, and
    # if it is, find the real file, and write to that. And if *that* file is
    # a soft link... go down the rabbit-hole as deep as it goes.
    while (-l $filename)
    {
        my $realfile = readlink $filename;
        if (-f $realfile)
        {
            $filename = $realfile;
        }
        else # give up and die
        {
            croak "$args{filename} is soft link, cannot find $realfile";
        }
    }
    return $filename;
} # _get_the_real_file

=head1 BUGS

Please report any bugs or feature requests to the author.

=cut

1; # End of File::Sticker::Reader::Exif
__END__
