package File::Sticker::Writer::Exif;
$File::Sticker::Writer::Exif::VERSION = '0.9301';
=head1 NAME

File::Sticker::Writer::Exif - write and standardize meta-data from EXIF file

=head1 VERSION

version 0.9301

=head1 SYNOPSIS

    use File::Sticker::Writer::Exif;

    my $obj = File::Sticker::Writer::Exif->new(%args);

    my %meta = $obj->write_meta(%args);

=head1 DESCRIPTION

This will write meta-data from EXIF files, and standardize it to a common
nomenclature, such as "tags" for things called tags, or Keywords or Subject etc.

=cut

use common::sense;
use File::LibMagic;
use Image::ExifTool qw(:Public);

use parent qw(File::Sticker::Writer);

# FOR DEBUGGING
=head1 DEBUGGING

=head2 whoami

Used for debugging info

=cut
sub whoami  { ( caller(1) )[3] }

=head1 METHODS

=head2 allowed_file

If this writer can be used for the given file, then this returns true.
File must be one of: an image or PDF. (ExifTool can't write to EPUB)

=cut

sub allowed_file {
    my $self = shift;
    my $file = shift;
    say STDERR whoami(), " file=$file" if $self->{verbose} > 2;

    $file = $self->_get_the_real_file(filename=>$file);
    my $ft = $self->{file_magic}->info_from_filename($file);
    if ($ft->{mime_type} =~ /(image|pdf)/)
    {
        return 1;
    }
    return 0;
} # allowed_file

=head2 known_fields

Returns the fields which this writer knows about.

    my $known_fields = $writer->known_fields();

=cut

sub known_fields {
    my $self = shift;

    return {
        title=>'TEXT',
        creator=>'TEXT',
        description=>'TEXT',
        location=>'TEXT',
        url=>'TEXT',
        tags=>'MULTI'};
} # known_fields

=head2 readonly_fields

Returns the fields which this writer knows about, which can't be overwritten,
but are allowed to be "wanted" fields. Things like file-size etc.

    my $readonly_fields = $writer->readonly_fields();

=cut

sub readonly_fields {
    my $self = shift;

    return {
        date=>'TEXT',
        copyright=>'TEXT',
        filesize=>'TEXT',
        flash=>'TEXT',
        imagesize=>'TEXT',
        imageheight=>'NUMBER',
        imagewidth=>'NUMBER',
        megapixels=>'NUMBER'};
} # readonly_fields

=head1 Helper Functions

Private interface.

=head2 replace_one_field

Overwrite the given field. This does no checking.

    $writer->replace_one_field(filename=>$filename,field=>$field,value=>$value);

=cut

sub replace_one_field {
    my $self = shift;
    my %args = @_;
    say STDERR whoami(), " filename=$args{filename}" if $self->{verbose} > 2;

    my $filename = $self->_get_the_real_file(filename=>$args{filename});
    my $field = $args{field};
    my $value = $args{value};

    my $ft = $self->{file_magic}->info_from_filename($filename);
    my $et = new Image::ExifTool;
    $et->Options(ListSep=>',',ListSplit=>',');

    my $success;
    if ($field eq 'url')
    {
        $success = $et->SetNewValue('Source', $value);
    }
    elsif ($field eq 'creator')
    {
        $success = $et->SetNewValue('Creator', $value);
    }
    elsif ($field eq 'title')
    {
        $success = $et->SetNewValue('Title', $value);
    }
    elsif ($field eq 'location')
    {
        $success = $et->SetNewValue('Location', $value);
    }
    elsif ($field eq 'description')
    {
        if ($ft->{mime_type} =~ /image\jpeg/)
        {
            $success = $et->SetNewValue('Comment', $value);
        }
        else
        {
            $success = $et->SetNewValue('Description', $value);
        }
    }
    elsif ($field eq 'tags')
    {
        if (ref $value eq 'ARRAY')
        {
            $success = $et->SetNewValue('Keywords', $value);
            $success = $et->SetNewValue('Subject', $value);
        }
        else
        {
            my @tags = split(/,/,$value);
            $success = $et->SetNewValue('Keywords', \@tags);
            $success = $et->SetNewValue('Subject', \@tags);
        }
    }

    if ($success)
    {
        $et->WriteInfo($filename);
    }
    return $success;
} # replace_one_field

=head2 delete_field_from_file

Completely remove the given field. This does no checking.

    $writer->delete_field_from_file(filename=>$filename,field=>$field);

=cut

sub delete_field_from_file {
    my $self = shift;
    my %args = @_;
    say STDERR whoami(), " filename=$args{filename}" if $self->{verbose} > 2;

    my $filename = $self->_get_the_real_file(filename=>$args{filename});
    my $field = $args{field};

    my $ft = $self->{file_magic}->info_from_filename($filename);
    my $et = new Image::ExifTool;
    $et->Options(ListSep=>',',ListSplit=>',');

    my $success;
    if ($field eq 'url')
    {
        $success = $et->SetNewValue('Source');
    }
    elsif ($field eq 'creator')
    {
        $success = $et->SetNewValue('Creator')
    }
    elsif ($field eq 'title')
    {
        $success = $et->SetNewValue('Title')
    }
    elsif ($field eq 'description')
    {
        if ($ft->{mime_type} =~ /image\/jpeg/)
        {
            $success = $et->SetNewValue('Comment');
        }
        else
        {
            $success = $et->SetNewValue('Description');
        }
    }
    elsif ($field eq 'tags')
    {
        $success = $et->SetNewValue('Keywords');
    }

    if ($success)
    {
        $et->WriteInfo($filename);
    }
    return $success;
} # delete_field_from_file

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

1; # End of File::Sticker::Writer
__END__
