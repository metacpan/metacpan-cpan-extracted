package File::Sticker::Reader::Exif;
$File::Sticker::Reader::Exif::VERSION = '0.9301';
=head1 NAME

File::Sticker::Reader::Exif - read and standardize meta-data from EXIF file

=head1 VERSION

version 0.9301

=head1 SYNOPSIS

    use File::Sticker::Reader::Exif;

    my $obj = File::Sticker::Reader::Exif->new(%args);

    my %meta = $obj->read_meta($filename);

=head1 DESCRIPTION

This will read meta-data from EXIF files, and standardize it to a common
nomenclature, such as "tags" for things called tags, or Keywords or Subject etc.

=cut

use common::sense;
use File::LibMagic;
use Image::ExifTool qw(:Public);
use File::Spec;

use parent qw(File::Sticker::Reader);

# FOR DEBUGGING
=head1 DEBUGGING

=head2 whoami

Used for debugging info

=cut
sub whoami  { ( caller(1) )[3] }

=head1 METHODS

=head2 allowed_file

If this reader can be used for the given file, then this returns true.
File must be one of: an image, PDF, or EPUB.

=cut

sub allowed_file {
    my $self = shift;
    my $file = shift;
    say STDERR whoami(), " filename=$file" if $self->{verbose} > 2;

    $file = $self->_get_the_real_file(filename=>$file);
    my $ft = $self->{file_magic}->info_from_filename($file);
    if ($ft->{mime_type} =~ /(image|pdf|epub)/)
    {
        say STDERR 'Reader ' . $self->name() . ' allows filetype ' . $ft->{mime_type} . ' of ' . $file if $self->{verbose} > 1;
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
        url=>'TEXT',
        creator=>'TEXT',
        date=>'TEXT',
        description=>'TEXT',
        copyright=>'TEXT',
        filesize=>'TEXT',
        flash=>'TEXT',
        imagesize=>'TEXT',
        imageheight=>'NUMBER',
        imagewidth=>'NUMBER',
        megapixels=>'NUMBER',
        location=>'TEXT',
        tags=>'MULTI'};
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
    foreach my $field (qw(Description Caption-Abstract Comment ImageDescription UserComment))
    {
        if (exists $info->{$field} and $info->{$field} and !$description)
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

    # The URL could be from the Source or the Identifier
    # Check through them until you find a non-empty one which contains an actual URL
    foreach my $field (qw(Source Identifier))
    {
        if (exists $info->{$field}
                and $info->{$field}
                and $info->{$field} =~ /^http/
                and !exists $meta{url})
        {
            $meta{url} = $info->{$field};
        }
    }

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
FileSize
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

    return \%meta;
} # read_meta

=head2 _get_the_real_file

If the file is a directory, look for a cover file.

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
    }
    return $filename;
} # _get_the_real_file

=head1 BUGS

Please report any bugs or feature requests to the author.

=cut

1; # End of File::Sticker::Reader::Exif
__END__
